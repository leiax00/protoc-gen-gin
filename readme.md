# protoc-gen-gin
> 针对gin实现的protobuff代码生成器

## 相关依赖及参考
1. [go -> 中文社区下载](https://studygolang.com/dl) -- (go version > 1.16)
2. [protoc](https://github.com/protocolbuffers/protobuf/releases)
3. [protoc-gen-go](https://github.com/protocolbuffers/protobuf-go/releases)
4. [protoc-gen-gogo: `go install github.com/gogo/protobuf/protoc-gen-gogo@latest`](https://github.com/gogo/protobuf/blob/master/protoc-gen-gogo)
5. [gin](https://github.com/gin-gonic/gin)
6. [protoc-go-inject-tag](https://github.com/favadi/protoc-go-inject-tag)

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
# 生成 example/api/common/v1/common.proto  -- 包含任意类型的自定义类型实现
protoc -I ./example/api --gogo_out=paths=source_relative:./example/api example/api/common/v1/common.proto
# inject tag: common.proto
protoc-go-inject-tag -input="example/api/common/v1/*.pb.go"

# 生成 example/api/demo/v1/api.proto
protoc -I ./example/api --gogo_out=paths=source_relative:./example/api --gin_out=paths=source_relative:./example/api example/api/demo/v1/api.proto

# 换行
```
## 针对inject tag进行生成
在生成`*.pb.go`之后通过 `[protoc-go-inject-tag](https://github.com/favadi/protoc-go-inject-tag)` 生成自定义tag
```shell
go install github.com/favadi/protoc-go-inject-tag@latest
protoc-go-inject-tag -input="*.pb.go"
# 生成自定义tag后删除注释tag
protoc-go-inject-tag -input="*.pb.go" -remove_tag_comment
```