module TimeHandler
  extend ActiveSupport::Concern

  def time_formatting(mins, time)
    minutes = time.min
    time = time.change(sec: 0)
    return time if minutes == 0
    unless mins == 60
      minutes -= 1 while minutes % mins != 0
      time = time.change(min: minutes)
      return time
    end
    time = time.change(min: 0)
    time
  end
end
