require 'csv'
require 'matrix'
require 'statsample'
require_relative 'base_function_util'

# require_relative 'max_data'

require 'nokogiri'
require 'open-uri'

class PredictionUtil
  def initialize
    @se_linear = +1.0/0.0
    @se_poly = +1.0/0.0
    @se_exp = +1.0/0.0
    @se_log = +1.0/0.0
    @regress_return = []
    @flag = ""
    @highest_temp = ""

    @prediction = []
    @probability = []

    @probability_linear
    @probability_poly
    @probability_exp
    @probability_log
    @result_prediction = []
  end

  def get_highes_temperature
    @max_temp_data = Hash.new
    @max_rain = Hash.new
    @max_wind_dir = Hash.new
    @max_wind_speed = Hash.new

    doc = Nokogiri::HTML(open("http://www.bom.gov.au/vic/observations/vicall.shtml"))
    doc.css("#content").each do |x|
      station = x.css("tr")
      station.each do |y|
        temp = y.css("a").text
        sta = temp if !temp.empty?
        b = y.css("a").map { |x| x['href']}
        if !b.empty?
          new_url = "http://www.bom.gov.au#{b.join()}"
          read = Nokogiri::HTML(open(new_url))
          recent = read.css("#content").each do |a|
            div = a.css("div").css("a")
            div_temp = div.to_s.match(/\/climate\/.+latest.shtml/).to_s
            if !div_temp.empty?
              recent_url = "http://www.bom.gov.au#{div_temp}"
              get = Nokogiri::HTML(open(recent_url))

              get.css(".data").each do |x|
                data_array = []
                data_array_rain = []
                data_array_dir = []
                data_array_speed = []

                (3..26).each do |i|
                  data_array << x.css("tr")[i].css("td")[2].text.to_f
                  data_array_rain << x.css("tr")[i].css("td")[3].text.to_f
                  dir = x.css("tr")[i].css("td")[6].text

                  data_array_dir  << BaseFunctionUtil.win_dir_to_number(dir)
                  data_array_speed << x.css("tr")[i].css("td")[7].text.to_f
                end
                @max_temp_data[read.css("h1").text[/for\ ([A-Za-z ]+)/,1]] = data_array
                @max_rain[read.css("h1").text[/for\ ([A-Za-z ]+)/,1]] = data_array_rain
                @max_wind_dir[read.css("h1").text[/for\ ([A-Za-z ]+)/,1]] = data_array_dir
                @max_wind_speed[read.css("h1").text[/for\ ([A-Za-z ]+)/,1]] = data_array_speed
              end
            end
          end
        end
      end
    end
  end

  #------------------------------linear--------------------------------------------
  def linear x_data, y_data
    temp = []
    x_vector = x_data.to_vector(:scale)
    y_vector = y_data.to_vector(:scale)
    ds = {'x'=>x_vector,'y'=>y_vector}.to_dataset
    linear = Statsample::Regression.multiple(ds,'y')
    @probability_linear = linear.r2_adjusted().round(2)
    temp[0] = linear.coeffs.fetch("x"){|k|puts k}.round(2)
    temp[1] = linear.constant.round(2)
    @regress_return = temp
    @se_linear = Math.sqrt(linear.mse.abs)
  end

  #-------------------------polynomial regression——————————————————————————————————
  def regress x_array, y_array, degree
    x_data = x_array.map { |x_i| (0..degree).map { |pow| (x_i**pow).to_f } }
    mx = Matrix[*x_data]
    my = Matrix.column_vector(y_array)
    @coefficients = ((mx.t * mx).inv * mx.t * my).transpose.to_a[0]
    @coefficients = @coefficients.collect{|item|item.round(2)}
  end

  def variation x_array, y_array, degree
    array_poly = []
    array_poly = regress x_array, y_array, degree
    array_poly1 = array_poly.reverse
    i = 0
    var = 0
    result = []
    while i < x_array.length
      sum = 0
      array_poly1.each do |x|
        sum = (sum + x)*x_array[i]
      end
      result[i] = (sum/x_array[i])
      i += 1
    end
    (0..x_array.length - 1).each{|x|var += ((y_array[x] - result[x]) ** 2)}
    puts var
    var = Math.sqrt(var/(x_array.length))
  end

  def polynomial x_array, y_array
    y_Average=y_array.inject{|r,a|r+a}.to_f/y_array.size
    array = []
    y_estimate = []
    (2..10).each{|x| array << (variation x_array, y_array, x)}
    index = (array.index(array.min) + 2)
    array1 = regress x_array, y_array, index
    @regress_return = array1.reverse
    ssr = 0
    sst = 0
    i = 0
    while i < x_array.length
      sum = 0
      @regress_return.each do |x|
        sum = (sum + x)*x_array[i]
      end
      y_estimate[i] = (sum/x_array[i])
      i += 1
    end

    for i in(0..y_array.length-1)
      ssr += (y_estimate[i] - y_Average)**2
      sst += (y_array[i] - y_Average)**2
    end

    @probability_poly = (ssr/sst).round(2)
    @se_poly = variation x_array, y_array, index
  end

  #————————————————————————————Exponential regression——————————————————————————————
  def exponential x_data, y_data
    temp = []
    log_y1_data = y_data.map { |y| Math.log(y)}
    x_vector = x_data.to_vector(:scale)
    y_vector = log_y1_data.to_vector(:scale)
    ds = {'x'=>x_vector,'y'=>y_vector}.to_dataset
    expon = Statsample::Regression.multiple(ds,'y')
    @probability_exp = expon.r2_adjusted().round(2)
    temp[0] = expon.coeffs.fetch("x"){|k|puts k}.round(2)
    temp[1] = (Math.exp(expon.constant)).round(2)
    @regress_return = temp
    @se_exp = Math.sqrt(expon.mse.abs)
    @se_exp = +1.0/0.0
  end

  #————————————————————————————Logarithmic regression——————————————————————————————
  def logarithmic x_data, y_data
    temp = []
    log_x_data = x_data.map { |x| Math.log(x) }
    x_vector = log_x_data.to_vector(:scale)
    y_vector = y_data.to_vector(:scale)
    ds = {'x'=>x_vector,'y'=>y_vector}.to_dataset
    log = Statsample::Regression.multiple(ds,'y')
    @probability_log = log.r2_adjusted().round(2)
    temp[0] = log.coeffs.fetch("x"){|k|puts k}.round(2)
    temp[1] = log.constant.round(2)
    @regress_return = temp
    @se_log = Math.sqrt(log.mse.abs)
  end

  #-----------------------------best_fit-------------------------------------------------
  def best_fit x_data, y_data
    mini_var = []
    mini_var << linear(x_data, y_data)
    mini_var << polynomial(x_data, y_data)
    exponential(x_data, y_data) if y_data.all?{|y| y>0 }
    logarithmic(x_data, y_data) if x_data.all?{|x| x>0 }
    mini_var << @se_exp
    mini_var << @se_log
    index = mini_var.index(mini_var.min)
    case index
    when 0
      @flag = "linear"
    when 1
      @flag = "poly"
    when 2
      @flag = "exp"
    when 3
      @flag = "log"
    end
  end

  def prediction_highTemp x_data, y_data, offset_time
    #例：x_data提供1，2，3，4，5.。。30 那么预测第30+offset_time天的最高温
    best_fit x_data, y_data
    if @flag.eql?("poly")
      sum = 0
      @regress_return.each do |x|
        sum = (sum + x)*(x_data[-1] + offset_time)
      end
      @highest_temp = sum/(x_data[-1] + offset_time)
    return @probability_poly
    elsif @flag.eql?("linear")
      @highest_temp = @regress_return[0]*(x_data[-1] + offset_time) + @regress_return[1]
    return  @probability_linear
    elsif @flag.eql?("log")
      @highest_temp = @regress_return[0]*((Math.log(x_data[-1] + offset_time))-@regress_return[1])**2
    return @probability_log
    elsif @flag.eql?("exp")
      @highest_temp = Math.exp((x_data[-1] + offset_time) * @regress_return[0]) + @regress_return[1]
    return @probability_exp
    end
  end

  def prediction_model x_data, y_data, period, highestTemperature, probability
    now=Time.now
    hour = now.hour
    min = now.min/60
    now_formatedtime = 24*hour/24 + min
    period = period/10
    i = 0
    result = []
    result_prediction = []
    best_fit x_data, y_data
    if @flag.eql?("poly")
      while i < x_data.length
        sum = 0
        @regress_return.each do |x|
          sum = (sum + x)*x_data[i]
        end
        result[i] = sum/x_data[i]
        i += 1
      end
      max_temp = result.max

      (1..period).each do |p|
        sum = 0
        @regress_return.each do |x|
          sum = (sum + x)*(now_formatedtime + p/6)
        end
        temp_time = sum/(now_formatedtime + p/6)
        @prediction << highestTemperature * (temp_time/max_temp)
        @probability << probability*@probability_poly
      end
      result_prediction << @prediction
      result_prediction << @probability
      puts "Here is the poly prediction: #{result_prediction}"
    elsif @flag.eql?("linear")
      while i< x_data.length
        result[i] = x_data[i]*@regress_return[0] + @regress_return[1]
        i += 1
      end
      max_temp = result.max

      (1..period).each do |p|
        temp_time =  (now_formatedtime + p/6)*@regress_return[0] + @regress_return[1]
        @prediction << highestTemperature * (temp_time/max_temp)
        @probability << probability*@probability_linear
      end

      result_prediction << @prediction
      result_prediction << @probability
      puts "Here is the linear prediction: #{result_prediction}"
    elsif @flag.eql?("log")
      while i< x_data.length
        result[i] = @regress_return[0]*((Math.log(x_data[i]))-@regress_return[1])**2
        i += 1
      end
      max_temp = result.max

      (0..period-1).each do |p|
        temp_time = @regress_return[0]*((Math.log(now_formatedtime + p/6))-@regress_return[1])**2
        @prediction = highestTemperature * (temp_time/max_temp)
        @probability << probability*@probability_log
      end
      result_prediction << @prediction
      result_prediction << @probability
      puts "Here is the log prediction: #{@prediction}"
    elsif @flag.eql?("exp")
      while i< x_data.length
        result[i] = Math.exp(x_data[i]*@regress_return[0]) + @regress_return[1]
        i += 1
      end
      max_temp = result.max
      (1..period).each do |p|
        temp_time = Math.exp((now_formatedtime + p/6) * @regress_return[0]) + @regress_return[1]
        @prediction = highestTemperature * (temp_time/max_temp)
        @probability << probability*@probability_exp
      end
      result_prediction << @prediction
      result_prediction << @probability
      puts "Here is the exp prediction: #{@prediction}"
    end
  end

  def prediction location, x_data, y_data, period
    get_highes_temperature
    x_data_hi = []
    y_data_hi = []
    y_data_hi = @max_temp_data[location]
    i = 1
    j = 0
    while i < y_data_hi.length+1
      x_data_hi[j] = i
      i = i+1
      j = j+1
    end
    probability = prediction_highTemp(x_data_hi, y_data_hi, 1)
    result_prediction = prediction_model(x_data, y_data, period, @highest_temp, probability)
  end
end


