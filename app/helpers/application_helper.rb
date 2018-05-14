module ApplicationHelper
  def bootstrap_class_for(flash_type)
    {
      success: "alert-success",
      error: "alert-danger",
      notice: "alert-info",
      warning: "alert-warning"
    }[flash_type.to_sym] || flash_type.to_s
  end

  def bootstrap_glyphs_icon(flash_type)
    {
      success: "glyphicon-ok",
      error: "glyphicon-exclamation-sign",
      notice: "glyphicon-info-sign",
      warning: "glyphicon-warning-sign"
    }[flash_type.to_sym] || 'glyphicon-screenshot'
  end
end
