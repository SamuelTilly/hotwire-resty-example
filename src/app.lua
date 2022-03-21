local template = require "resty.template"
local router = require "router"
local httpc = require("resty.http").new()
local r = router.new()

local stream = template.compile("template/turbo-stream.html")
local msg = template.compile("template/message.html")

r:get("/", function()
  template.render("index.html")
end)

r:post("/send", function(params)
  -- Make this a function and call using ngx threads
  local res, err = httpc:request_uri("http://127.0.0.1:8080/messages", {
    method = "POST",
    body = stream{ 
      action = "append", 
      target = "messages",  
      content = msg{ message = params.content }
    }
  })
  if not res then
    ngx.log(ngx.ERR, "request failed: ", err)
    return
  end
  r:execute('GET',  '/')
end)

local ok, errmsg = r:execute(
  ngx.var.request_method,
  ngx.var.uri,
  ngx.req.get_uri_args(),  -- all these parameters
  ngx.req.get_post_args(), -- will be merged in order
  {other_arg = 1})         -- into a single "params" table

if not ok then
  ngx.status = 404
  ngx.print("Not found!")
  ngx.log(ngx.ERR, errmsg)
end
