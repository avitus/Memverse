def screenshot
  path = Rails.root.join("local", "screenshot.png")
  File.delete(path) if File.exists?(path)

  save_screenshot(path, full: true)
  Launchy.open(path.to_s)
end
