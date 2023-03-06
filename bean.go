package main

import (
	"bytes"
	_ "embed"
	"fmt"
	"html/template"
	"strings"
)

//go:embed template.go.tpl
var tpl string

type service struct {
	OptsList []string // 额外输出信息
	Name     string   // Greeter
	FullName string   // helloworld.Greeter
	FilePath string   // api/helloworld/helloworld.proto

	MethodSet map[string]*method // 接口方法
	Methods   []*method
}

// InterfaceName service interface name
func (s *service) InterfaceName() string {
	return s.Name + "HttpServer"
}

func (s *service) toCode() string {
	if s.MethodSet == nil {
		s.MethodSet = map[string]*method{}
		for _, m := range s.Methods {
			m := m
			s.MethodSet[m.Name] = m
		}
	}
	buf := new(bytes.Buffer)
	tmpl, err := template.New("http").Parse(strings.TrimSpace(tpl))
	if err != nil {
		panic(err)
	}
	if err := tmpl.Execute(buf, s); err != nil {
		panic(err)
	}
	return strings.Join(s.OptsList, "\n") + buf.String()
}

type method struct {
	Name    string // SayHello
	Num     int    // 在一个rpc对一个多个http时, 作为方法的唯一标识
	Request string // SayHelloReq
	Reply   string // SayHelloResp
	Route   *route
}

type route struct {
	Path         string // 路由
	Method       string // HTTP Method
	Body         string
	ResponseBody string
}

// initPathParams 转换参数路由 {xx} --> :xx
func (m *method) initPathParams() {
	paths := strings.Split(m.Route.Path, "/")
	for i, p := range paths {
		if len(p) > 0 && (p[0] == '{' && p[len(p)-1] == '}' || p[0] == ':') {
			paths[i] = ":" + p[1:len(p)-1]
		}
	}
	m.Route.Path = strings.Join(paths, "/")
}

// HandlerName for gin handler name
func (m *method) HandlerName() string {
	return fmt.Sprintf("%s%d", m.Name, m.Num)
}

// HasPathParams 是否包含路由参数
func (m *method) HasPathParams() bool {
	paths := strings.Split(m.Route.Path, "/")
	for _, p := range paths {
		if len(p) > 0 && (p[0] == '{' && p[len(p)-1] == '}' || p[0] == ':') {
			return true
		}
	}
	return false
}
