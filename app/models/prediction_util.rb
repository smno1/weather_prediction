require 'csv'
require 'matrix'
require 'statsample'

class Regression
  def initialize
    @se_linear = +1.0/0.0
    @se_poly = +1.0/0.0
    @se_exp = +1.0/0.0
    @se_log = +1.0/0.0
    @regress_return = []
    @flag = ""
    @highest_temp 
  end

  #------------------------------linear--------------------------------------------
  def linear x_data, y_data
    temp = []
    x_vector = x_data.to_vector(:scale)
    y_vector = y_data.to_vector(:scale)
    ds = {'x'=>x_vector,'y'=>y_vector}.to_dataset
    linear = Statsample::Regression.multiple(ds,'y')
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
    var = Math.sqrt(var/(x_array.length - degree - 1 ))
  end

  def polynomial x_array, y_array
    array = []
    (2..10).each{|x| array << (variation x_array, y_array, x)}
    index = (array.index(array.min) + 2)
    array1 = regress x_array, y_array, index
    @regress_return = array1.reverse
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
    temp[0] = expon.coeffs.fetch("x"){|k|puts k}.round(2)
    temp[1] = (Math.exp(expon.constant)).round(2)
    @regress_return = temp
    @se_exp = Math.sqrt(expon.mse.abs)
    end

  #————————————————————————————Logarithmic regression——————————————————————————————
  def logarithmic x_data, y_data
    temp = []
    log_x_data = x_data.map { |x| Math.log(x) }
    x_vector = log_x_data.to_vector(:scale)
    y_vector = y_data.to_vector(:scale)
    ds = {'x'=>x_vector,'y'=>y_vector}.to_dataset
    log = Statsample::Regression.multiple(ds,'y')
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
      linear(x_data, y_data){|output| puts output}
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
    elsif @flag.eql?("linear")
      @highest_temp = @regress_return[0]*(x_data[-1] + offset_time) + @regress_return[1]
    elsif @flag.eql?("log")
      @highest_temp = @regress_return[0]*((Math.log(x_data[-1] + offset_time))-@regress_return[1])**2
    elsif @flag.eql?("exp")
      @highest_temp = Math.exp((x_data[-1] + offset_time) * @regress_return[0]) + @regress_return[1]
    end  
  end
  
 def prediction_model x_data, y_data, period
    i = 0
    result = []
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
      sum = 0
      @regress_return.each do |x|
        sum = (sum + x)*(x_data[-1]+period)
      end
      temp_time = sum/(x_data[-1]+period)
      @prediction = @highest_temp * (temp_time/max_temp)
      puts "Here is the poly prediction: #{@prediction}"
    elsif @flag.eql?("linear")
      while i< x_data.length
        result[i] = x_data[i]*@regress_return[0] + @regress_return[1]
        i += 1
      end
      max_temp = result.max
      temp_time =  (x_data[-1]+period)*@regress_return[0] + @regress_return[1]
      @prediction = @highest_temp * (temp_time/max_temp)
      puts "Here is the linear prediction: #{@prediction}"
    elsif @flag.eql?("log")
      while i< x_data.length
        result[i] = @regress_return[0]*((Math.log(x_data[i]))-@regress_return[1])**2
        i += 1
      end   
      max_temp = result.max
      temp_time = @regress_return[0]*((Math.log(x_data[-1]+period))-@regress_return[1])**2 
      @prediction = @highest_temp * (temp_time/max_temp)
      puts "Here is the log prediction: #{@prediction}"
    elsif @flag.eql?("exp")
      while i< x_data.length
        result[i] = Math.exp(x_data[i]*@regress_return[0]) + @regress_return[1]
        i += 1
      end
      max_temp = result.max
      temp_time = Math.exp((x_data[-1] + period) * @regress_return[0]) + @regress_return[1]
      @prediction = @highest_temp * (temp_time/max_temp)
      puts "Here is the exp prediction: #{@prediction}"
    end
  end
end

#---------------------------end of class----------------------------------------------------
regress_test = Regression.new
x_data = []
y_data = []
time = 15
CSV.foreach("input_3.txt", headers:true).each do |line|
  y_data << line['datapoint'].to_f
  x_data << line['time'].to_f
end

regress_test.prediction_highTemp x_data, y_data, time
regress_test.prediction_model x_data, y_data, time
