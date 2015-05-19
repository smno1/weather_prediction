require 'csv'
require 'matrix'
require 'statsample'

class Regression
  def initialize
    @se_linear = +1.0/0.0
    @se_poly = +1.0/0.0
    @se_exp = +1.0/0.0
    @se_log = +1.0/0.0
    @linear_return = []
    @poly_return = []
    @log_return = []
    @exp_return = []
    @prediction
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
    @linear_return = temp
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
    @poly_return = array1.reverse

    k = index
    poly_string = ""
    while k >= 0
      poly_string << "#{array1[k]}x^#{k} + " if (array1[k] != 0) && (k > 1)
      poly_string << "#{array1[k]}x + " if k == 1
      poly_string << "#{array1[k]} " if k == 0
      k = k - 1
    end
    output = poly_string.gsub(/\+ ?-/, '- ')
    yield output if block_given?
    @se_poly = variation x_array, y_array, index
  #  puts @se_poly
  end

  #————————————————————————————Exponential regression——————————————————————————————
  def exponential x_data, y_data
    log_y1_data = y_data.map { |y| Math.log(y)}
    x_vector = x_data.to_vector(:scale)
    y_vector = log_y1_data.to_vector(:scale)
    ds = {'x'=>x_vector,'y'=>y_vector}.to_dataset
    expon = Statsample::Regression.multiple(ds,'y')
    output = "#{(Math.exp(expon.constant)).round(2)}*e^(#{expon.coeffs.fetch("x"){|k|puts k}.round(2)}x)"
    yield output if block_given?
    @se_exp = Math.sqrt(expon.mse.abs)
    #  puts @se_exp
  rescue Math::DomainError
    puts "Cannot perform exponential regression on this data"
    end

  #————————————————————————————Logarithmic regression——————————————————————————————
  def logarithmic x_data, y_data

    log_x_data = x_data.map { |x| Math.log(x) }
    x_vector = log_x_data.to_vector(:scale)
    y_vector = y_data.to_vector(:scale)
    ds = {'x'=>x_vector,'y'=>y_vector}.to_dataset
    log = Statsample::Regression.multiple(ds,'y')
    # puts log.mse
    output= "#{log.coeffs.fetch("x"){|k|puts k}.round(2)}*ln(x) + #{log.constant.round(2)}".gsub(/\+ ?-/, '- ')
    yield output if block_given?
    @se_log = Math.sqrt(log.mse.abs)
    #  puts @se_log
  rescue Math::DomainError
    puts "Cannot perform logarithmic regression on this data"
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
    
    # print mini_var
    
    
    index = mini_var.index(mini_var.min)
    case index
    when 0
      @flag = "linear"
      linear(x_data, y_data){|output| puts output}
    when 1
      @flag = "poly"
    # polynomial(x_data, y_data){|output| puts output}
    when 2
      exponential(x_data, y_data){|output| puts output}
    when 3
      logarithmic(x_data, y_data){|output| puts output}
    end
  end

  def prediction_highTemp x_data, y_data
    #例：x_data提供1，2，3，4，5.。。30 那么预测第30+1天的最高温
    best_fit x_data, y_data
    if @flag.eql?("poly")
      sum = 0
      @poly_return.each do |x|
        sum = (sum + x)*(x_data[-1] + 1)
      end
      @highest_temp = (sum/(x_data[-1] + 1))
    elsif @flag.eql?("linear")
      @highest_temp = @linear_return[0]*(x_data[-1] + 1) + @linear_return[1]
    end   
  end
  
 def prediction_model x_data, y_data, time
    i = 0
    result = []
    best_fit x_data, y_data
    if @flag.eql?("poly")
      while i < x_data.length
        sum = 0
        @poly_return.each do |x|
          sum = (sum + x)*x_data[i]
        end
        result[i] = sum/x_data[i]
        i += 1
      end
      max_temp = result.max
      sum = 0
      @poly_return.each do |x|
        sum = (sum + x)*time
      end
      temp_time = sum/time
      @prediction = @highest_temp * (temp_time/max_temp)
      puts "Here is the prediction: #{@prediction}"
    elsif @flag.eql?("linear")
      while i< x_data.length
        result[i] = x_data[i]*@linear_return[0] + @linear_return[1]
        i += 1
      end
      max_temp = result.max
      temp_time =  time*@linear_return[0] + @linear_return[1]
      @prediction = @highest_temp * (temp_time/max_temp)
      puts "Here is the prediction: #{@prediction}"
    end

  end

end

#-----------------------------prediction------------------------------------------------------



#---------------------------end of class----------------------------------------------------

regress_test = Regression.new
x_data = []
y_data = []
time = 15
CSV.foreach("input_2.txt", headers:true).each do |line|
  y_data << line['datapoint'].to_f
  x_data << line['time'].to_f
end

regress_test.prediction_highTemp x_data, y_data
regress_test.prediction_model x_data, y_data, time

# case ARGV[1]
# when "linear"
  # regress_test.linear(x_data, y_data) {|output| puts output}
# when "polynomial"
  # regress_test.polynomial(x_data, y_data) {|output| puts output}
# when "exponential"
  # regress_test.exponential(x_data, y_data) {|output| puts output}
# when "logarithmic"
  # regress_test.logarithmic(x_data, y_data) {|output| puts output}
# when "best_fit"
  # regress_test.best_fit(x_data, y_data)
# end
