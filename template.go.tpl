type {{ $.InterfaceName }} interface {
{{- range .MethodSet}}
	{{.Name}}(context.Context, *{{.Request}}) (*{{.Reply}}, error)
{{end}}
}

type {{$.Name}}Ctl struct {
	srv {{ $.InterfaceName }}
}

func Register{{ $.InterfaceName }}(r gin.IRouter, srv {{ $.InterfaceName }}) {
  ctl := &{{$.Name}}Ctl {srv}
{{- range .Methods}}
  r.Handle("{{.Route.Method}}", "{{.Route.Path}}", ctl._{{ .HandlerName }})
{{- end}}
}

{{range .Methods}}
func (ctl *{{$.Name}}Ctl) _{{ .HandlerName }}(ctx *gin.Context) {
  var in {{.Request}}
{{if .HasPathParams }}
  if err := ctx.ShouldBindUri(&in); err != nil {
    ctl.paramsError(ctx, err)
    return
  }
{{end}}
{{if eq .Route.Method "GET" "DELETE" }}
  if err := ctx.ShouldBindQuery(&in); err != nil {
    ctl.paramsError(ctx, err)
    return
  }
{{else if eq .Route.Method "POST" "PUT" }}
  if err := ctx.ShouldBindJSON(&in); err != nil {
    ctl.paramsError(ctx, err)
    return
  }
{{else}}
  if err := ctx.ShouldBind(&in); err != nil {
    ctl.paramsError(ctx, err)
    return
  }
{{end}}
  md := metadata.New(nil)
  for k, v := range ctx.Request.Header {
    md.Set(k, v...)
  }
  newCtx := metadata.NewIncomingContext(ctx, md)
  out, err := ctl.srv.{{.Name}}(newCtx, &in)
  if err != nil {
    ctl.error(ctx, err)
    return
  }
  ctl.ok(ctx, out)
}
{{end}}

func (ctl *{{$.Name}}Ctl) response(ctx *gin.Context, httpCode, rpcCode int, msg any, data any)  {
	ctx.JSON(httpCode, struct {
    Code int `json:"code"`
    Msg any `json:"msg,omitempty"`
    Data any `json:"data,omitempty"`
  }{rpcCode, msg, data})
}

func (ctl *{{$.Name}}Ctl) error(ctx *gin.Context, err error)  {
	httpCode := 500
	rpcCode := -1
	reason := "UNKNOWN_ERR"
	msg := "UNKNOWN_ERR"

	if err == nil {
		msg += ", err is nil"
		ctl.response(ctx, httpCode, rpcCode, msg, nil)
		return
	}

	type iCode interface{
		GetCode() int32
		GetGrpcCode() int32
		GetReason() string
		GetMessage() string
	}

	var c iCode
	if errors.As(err, &c) {
		httpCode = int(c.GetCode())
		rpcCode = int(c.GetGrpcCode())
		reason = c.GetReason()
		msg = c.GetMessage()
	}

	_ = ctx.Error(err)

	ctl.response(ctx, httpCode, rpcCode, reason, nil)
}

func (ctl *{{$.Name}}Ctl) paramsError (ctx *gin.Context, err error) {
	_ = ctx.Error(err)
	ctl.response(ctx, 400, 400, "PARAM_ERR", nil)
}

func (ctl *{{$.Name}}Ctl) ok(ctx *gin.Context, data any) {
	ctl.response(ctx, 200, 0, nil, data)
}