local ok, runfile = pcall(require, "runfile")
if ok and runfile then
  runfile.setup_commands()
end
