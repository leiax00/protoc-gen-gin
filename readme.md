# protoc-gen-gin
> 针对gin实现的protobuff代码生成器

## 相关依赖及参考
1. [go -> 中文社区下载](https://studygolang.com/dl) -- (go version > 1.16)
2. [protoc](https://github.com/protocolbuffers/protobuf/releases)
3. [protoc-gen-go](https://github.com/protocolbuffers/protobuf-go/releases)
4. [gin](https://github.com/gin-gonic/gin)
5. [protoc-go-inject-tag](https://github.com/favadi/protoc-go-inject-tag)

## 基本使用
```shell
go install github.com/leiax00/protoc-gen-gin@latest
```

## proto文件定义
```protobuf

service DemoService {
  rpc GetDemoM1(DemoReq) returns (DemoResp) {
    // 
    // 可以通过添加 additional_bindings 使一个 rpc 方法对应多个路由
    option (google.api.http) = {
      get: "/v1/route1"
      additional_bindings {
        get: "/v1/route2/{param_1}"
//        ...
      }
    };
  }
}
```
## 生成命令
```shell
protoc --proto_path=./third_party -I ./example/api --go_out ./example/api --go_opt=paths=source_relative --gin_out ./example/api --gin_opt=paths=source_relative example/api/demo/v1/api.proto
# 换行
protoc --proto_path=./third_party \
        -I ./example/api \
        --go_out ./example/api \
        --go_opt=paths=source_relative \
        --gin_out ./example/api \
        --gin_opt=paths=source_relative \
        example/api/demo/v1/api.proto
```