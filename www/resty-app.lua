ngx.print(
    "<html><body>",
    "<p>Hello NGINX-Lua!</p>",
    "<p>PATH=" .. ngx.var.document_uri .. "</p>")
if ngx.var.document_uri=='/multiply' then
    ngx.print("<p>RESULT: ", ngx.var.arg_a, "*", ngx.var.arg_b, "=", ngx.var.arg_a*ngx.var.arg_b, "</p>")
end
ngx.print("</body></html>\n")
