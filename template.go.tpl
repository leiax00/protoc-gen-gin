type {{ $.InterfaceName }} interface {
{{- range .MethodSet}}
	{{.Name}}(context.Context, *{{.Request}}) (*{{.Reply}}, error)
{{end}}
}

func Register{{ $.InterfaceName }}(r gin.IRouter, srv {{ $.InterfaceName }}) {
{{- range .Methods}}
  r.Handle("{{.Route.Method}}", "{{.Route.Path}}", _{{$.Name}}{{ .HandlerName }}(srv))
{{- end}}
}

// Resp 返回值
type default{{$.Name}}Resp struct {}

func (resp default{{$.Name}}Resp) response(ctx *gin.Context, status, code int, msg string, data interface{}) {
	ctx.JSON(status, map[string]interface{}{
		"code": code,
		"msg": msg,
		"data": data,
	})
}

// Error 返回错误信息
func (resp default{{$.Name}}Resp) Error(ctx *gin.Context, err error) {
	code := -1
	status := 500
	msg := "未知错误"

	if err == nil {
		msg += ", err is nil"
		resp.response(ctx, status, code, msg, nil)
		return
	}

	type iCode interface{
		HTTPCode() int
		Message() string
		Code() int
	}

	var c iCode
	if errors.As(err, &c) {
		status = c.HTTPCode()
		code = c.Code()
		msg = c.Message()
	}

	_ = ctx.Error(err)

	resp.response(ctx, status, code, msg, nil)
}

// ParamsError 参数错误
func (resp default{{$.Name}}Resp) ParamsError (ctx *gin.Context, err error) {
	_ = ctx.Error(err)
	resp.response(ctx, 400, 400, "参数错误", nil)
}

// Success 返回成功信息
func (resp default{{$.Name}}Resp) Success(ctx *gin.Context, data interface{}) {
	resp.response(ctx, 200, 0, "成功", data)
}


{{range .Methods}}
func _{{$.Name}}{{ .HandlerName }}(srv {{ $.InterfaceName }}) func(ctx *gin.Context) {
  return func(ctx *gin.Context) {
    var in {{.Request}}
    var resp = default{{$.Name}}Resp{}
  {{if .HasPathParams }}
    if err := ctx.ShouldBindUri(&in); err != nil {
      resp.ParamsError(ctx, err)
      return
    }
  {{end}}
  {{if eq .Route.Method "GET" "DELETE" }}
  	if err := ctx.ShouldBindQuery(&in); err != nil {
  		resp.ParamsError(ctx, err)
  		return
  	}
  {{else if eq .Route.Method "POST" "PUT" }}
  	if err := ctx.ShouldBindJSON(&in); err != nil {
  		resp.ParamsError(ctx, err)
  		return
  	}
  {{else}}
  	if err := ctx.ShouldBind(&in); err != nil {
  		resp.ParamsError(ctx, err)
  		return
  	}
  {{end}}
    md := metadata.New(nil)
  	for k, v := range ctx.Request.Header {
  		md.Set(k, v...)
  	}
  	newCtx := metadata.NewIncomingContext(ctx, md)
  	out, err := srv.{{.Name}}(newCtx, &in)
  	if err != nil {
  		resp.Error(ctx, err)
  		return
  	}

  	resp.Success(ctx, out)
  }
}
{{end}}
