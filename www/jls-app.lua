local httpServer = ...

local StringBuffer = require('jls.lang.StringBuffer')

httpServer:removeAllContexts()

httpServer:createContext('/?(.*)', function(exchange)
  local path = exchange:getRequestArguments()
  local args = exchange:getSearchParams()
  local body = StringBuffer:new()
  body:append("<html><body>" ..
    "<p>Hello Apache " .. _VERSION .. "!</p>" ..
    "<p>PATH=" .. path .. "</p>")
  --body:append("<p>TARGET=" .. exchange:getRequest():getTarget() .. "</p>")
  if path == 'multiply' then
    body:append("<p>RESULT: " .. args.a .."*" .. args.b .. "=" .. args.a*args.b .. "</p>")
  end
  body:append("</body></html>\n")
  local response = exchange:getResponse()
  response:setHeader('content-type', 'text/html')
  response:setBody(body)
end)
