require 'nokogiri'
require 'open-uri'

class PredictionUtil
  def initialize
    @se_linear = +1.0/0.0
    @se_poly = +1.0/0.0
    @se_exp = +1.0/0.0
    @se_log = +1.0/0.0
    @regress_return_linear = []
    @regress_return_poly = []
    @regress_return_log = []
    @regress_return_exp = []
    @flag = ""
    @highest_temp = ""
    @result_prediction = []
  end

  def get_highest_temperature
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
                @max_temp_data[read.css("h1").text[/for\ ([A-Za-z \(\)]+)/,1]] = data_array
                @max_rain[read.css("h1").text[/for\ ([A-Za-z \(\)]+)/,1]] = data_array_rain
                @max_wind_dir[read.css("h1").text[/for\ ([A-Za-z \(\)]+)/,1]] = data_array_dir
                @max_wind_speed[read.css("h1").text[/for\ ([A-Za-z \(\)]+)/,1]] = data_array_speed
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
    puts "======@probability_linear========#{@probability_linear}=============@probability_linear====="
    temp[0] = linear.coeffs.fetch("x"){|k|puts k}.round(2)
    temp[1] = linear.constant.round(2)
    @regress_return_linear = temp
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
    var = Math.sqrt(var/(x_array.length))
  end
  
  def polynomial x_array, y_array
    y_Average=y_array.inject{|r,a|r+a}.to_f/y_array.size
    array = []
    y_estimate = []
    (2..10).each{|x| 
    # puts "==============================test #{x}===================="
      # puts x_array.inspect
      # puts y_array.inspect
      # puts (variation x_array, y_array, x)
    # puts "==============================test===================="
      array << (variation x_array, y_array, x)}
    # puts array.inspect
    # puts array.min
    index = BaseFunctionUtil.get_min_from_a_mix_array array
    unless index==-1
      array1 = regress x_array, y_array, index
      @regress_return_poly = array1.reverse
      ssr = 0
      sst = 0
      i = 0
      while i < x_array.length
        sum = 0
        @regress_return_poly.each do |x|
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
          puts "======@probability_poly========#{@probability_poly}=============@probability_poly====="
      @se_poly = variation x_array, y_array, index
    else
      @se_poly =Float::NAN
    end
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
    puts "======@probability_exp========#{@probability_exp}=============@probability_exp====="
    temp[0] = expon.coeffs.fetch("x"){|k|puts k}.round(2)
    temp[1] = (Math.exp(expon.constant)).round(2)
    @regress_return_exp = temp
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
    puts "======@probability_log========#{@probability_log}=============@probability_log====="
    temp[0] = log.coeffs.fetch("x"){|k|puts k}.round(2)
    temp[1] = log.constant.round(2)
    @regress_return_log = temp
    @se_log = Math.sqrt(log.mse.abs)
  end

  #-----------------------------best_fit-------------------------------------------------
  def best_fit x_data, y_data
    mini_var = []
    linear(x_data, y_data)
    if @se_linear.nan?
      mini_var << +1.0/0.0
    else
      mini_var << @se_linear 
    end
  
    
    polynomial(x_data, y_data)
    if @se_poly.nan?
      mini_var << +1.0/0.0
    else
      mini_var << @se_poly
    end
    
    
    exponential(x_data, y_data) if y_data.all?{|y| y>0 }
    logarithmic(x_data, y_data) if x_data.all?{|x| x>0 }

    if @se_exp.nan?
      mini_var << +1.0/0.0
    else
      mini_var << @se_exp
    end

    if @se_log.nan?
      mini_var << +1.0/0.0
    else
      mini_var << @se_log
    end
    
    # mini_var << @se_exp
    # mini_var << @se_log
    
    
    # puts "=========test best fit==========="
    # puts mini_var.inspect
    # puts "=========test best fit==========="
    index = BaseFunctionUtil.get_min_from_a_mix_array mini_var
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
    puts "x_data highTemp"
    puts x_data.inspect
    puts "y_data highTemp"
    puts y_data.inspect
    best_fit x_data, y_data
    puts "@flag"
    puts @flag
      if @flag.eql?("poly")
      sum = 0
      @regress_return_poly.each do |x|
        sum = (sum + x)*(x_data[-1] + offset_time)
      end
      @highest_temp = sum/(x_data[-1] + offset_time)
      puts "@highest_temp"
      puts @highest_temp
      puts "@probability_poly"
      puts @probability_poly
    return @probability_poly
    elsif @flag.eql?("linear")
      @highest_temp = @regress_return_linear[0]*(x_data[-1] + offset_time) + @regress_return_linear[1]
      puts "@highest_temp"
      puts @highest_temp
      puts "@probability_linear"
      puts @probability_linear
    return  @probability_linear
    elsif @flag.eql?("log")
      @highest_temp = @regress_return_log[0]*((Math.log(x_data[-1] + offset_time)))+@regress_return_log[1]
      puts "@highest_temp"
      puts @highest_temp
      puts" @probability_log"
      puts @probability_log
    return @probability_log
    elsif @flag.eql?("exp")
      @highest_temp = Math.exp((x_data[-1] + offset_time) * @regress_return_exp[0]) + @regress_return_exp[1]
      puts "@highest_temp"
      puts @highest_temp
      puts "@probability_exp"
      puts @probability_exp
    return @probability_exp
    end
  end

  def prediction_model x_data, y_data, period, highestTemperature, probability
    now=Time.now
    hour = now.hour
    min = now.min/60.0
    now_formatedtime = hour.to_f + min
    period = period/10
    i = 0
    prediction_array = []
    probability_array = []
    result = []
    result_prediction = []
    
    best_fit x_data, y_data
    
    if @flag.eql?("poly")
      while i < x_data.length
        sum = 0
     # puts "==========test=====max======"
     # puts result
     # puts "==========test=====max======"
     max_temp = result.max
        @regress_return_poly.each do |x|
          sum = (sum + x)*(x_data[i].to_f)
        end
        result[i] = sum/(x_data[i].to_f)
        i += 1
      end
      # puts "==========test=====max======"
      # puts result
      # puts "==========test=====max======"
      max_temp = result.max

      (1..period).each do |p|
        sum = 0
        @regress_return_poly.each do |x|
          sum = (sum + x)*(now_formatedtime + p/6.0)
        end
        temp_time = sum/(now_formatedtime + p/6.0)
        prediction_array << (highestTemperature * (temp_time/max_temp)).round(3)
        probability_array << ((probability*@probability_poly).abs).round(3)
      end
      result_prediction << prediction_array
      result_prediction << probability_array
      return result_prediction
      # puts "Here is the poly prediction: #{result_prediction}"
    elsif @flag.eql?("linear")
      while i< x_data.length
        result[i] = x_data[i].to_f*@regress_return_linear[0] + @regress_return_linear[1]
        i += 1
      end
      max_temp = result.max

      (0..period-1).each do |p|
        temp_time =  (now_formatedtime + p/6.0)*@regress_return_linear[0] + @regress_return_linear[1]
        prediction_array << (highestTemperature * (temp_time/max_temp)).round(3)
        probability_array << ((probability*@probability_linear).abs).round(3)
      end

      result_prediction << prediction_array
      result_prediction << probability_array
      return result_prediction
      # puts "Here is the linear prediction: #{result_prediction}"
    elsif @flag.eql?("log")
      while i< x_data.length
        result[i] = @regress_return_log[0]*(Math.log(x_data[i]==0? 24:x_data[i]))+@regress_return_log[1]
      puts "result #{i}==========="
      puts result[i],x_data[i]
        i += 1
      end
      max_temp = result.max
      puts "max_temp"
      puts max_temp

      (0..period-1).each do |p|
        temp_time = @regress_return_log[0]*(Math.log(now_formatedtime + p/6.0))+@regress_return_log[1]
        prediction_array << (highestTemperature * (temp_time/max_temp)).round(3)
        probability_array << ((probability*@probability_log).abs).round(3)
      end
      result_prediction << prediction_array
      result_prediction << probability_array
      return result_prediction
      # puts "Here is the log prediction: #{@prediction}"
    elsif @flag.eql?("exp")
      while i< x_data.length
        result[i] = Math.exp(x_data[i]*@regress_return_exp[0]) + @regress_return_exp[1]
        i += 1
      end
      max_temp = result.max
      (1..period).each do |p|
        temp_time = Math.exp((now_formatedtime + p/6.0) * @regress_return_exp[0]) + @regress_return_exp[1]
        prediction_array << (highestTemperature * ((temp_time/max_temp)).abs).round(3)
        probability_array << ((probability*@probability_exp).abs).round(3)
      end
      result_prediction << prediction_array
      result_prediction << probability_array
      return result_prediction
      # puts "Here is the exp prediction: #{@prediction}"
    end
  end

  def prediction location, x_data, y_data_temp, y_data_rain, y_data_wind_dir, y_data_wind_speed , period
    # puts "===============test input==========="
    # puts x_data
    # print y_data_temp
    # puts "===============test input==========="
    get_highest_temperature
    x_data_hi = []
    y_data_hi_rain = []
    y_data_hi_wind_dir = []
    y_data_hi_wind_speed = []
    y_data_hi_temp = @max_temp_data[location]
    y_data_hi_rain = @max_rain[location]
    y_data_hi_wind_dir = @max_wind_dir[location]
    y_data_hi_wind_speed = @max_wind_speed[location]
    puts "@max_temp_data[location]"
    puts y_data_hi_temp.inspect
    puts "@max_rain[location]"
    puts y_data_hi_rain.inspect
    puts "@max_wind_dir[location]"
    puts y_data_hi_wind_dir.inspect 
    puts "@max_wind_speed[location]"
    puts y_data_hi_wind_speed.inspect

    # choose which set of data to get(temperature, wind or rain)
    #generate the data set of x_data_hi
    i = 1
    j = 0
    while i < y_data_hi_temp.length+1
      x_data_hi[j] = i
      i = i+1
      j = j+1
    end
    
    @return_prediction = Hash.new
    probability_temp = prediction_highTemp(x_data_hi, y_data_hi_temp, 1)   
    @return_prediction['temperature'] = prediction_model(x_data, y_data_temp, period, @highest_temp, probability_temp)
    puts "=============test result==========****************"
    puts "@return_prediction['temperature']:"
    puts @return_prediction['temperature']
    puts "=============test result==========****************"
    
    probability_rain = prediction_highTemp(x_data_hi, y_data_hi_rain, 1)
    @return_prediction['rain'] = prediction_model(x_data, y_data_rain, period, @highest_temp, probability_rain)
    puts "=============test result==========****************"
    puts  "@return_prediction['rain']"
    puts  @return_prediction['rain']
    puts "=============test result==========****************"
   
    probability_wind_dir = prediction_highTemp(x_data_hi, y_data_hi_wind_dir, 1)
    @return_prediction['wind_dir'] = prediction_model(x_data, y_data_wind_dir, period, @highest_temp, probability_wind_dir)
    puts "=============test result==========****************"
    puts "@return_prediction['wind_dir']"
    puts @return_prediction['wind_dir']
    puts "=============test result==========****************"
   
    probability_wind_speed = prediction_highTemp(x_data_hi, y_data_hi_wind_speed, 1)
    @return_prediction['wind_speed'] = prediction_model(x_data, y_data_wind_speed, period, @highest_temp, probability_wind_speed)
    puts "=============test result==========****************"
    puts  "@return_prediction['wind_speed']"
    puts  @return_prediction['wind_speed']
    puts "=============test result==========****************"
    @return_prediction
  end


end
