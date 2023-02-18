package main

import (
	"net/http"

	"github.com/labstack/echo/v4"
)

func main() {
	e := echo.New()
	e.GET("/", func(c echo.Context) error {
		return c.String(http.StatusOK, "OK")
	})
	e.GET("/health", func(c echo.Context) error {
		return c.String(http.StatusOK, "OK")
	})
	e.GET("/:path1/:path2", func(c echo.Context) error {
		return c.String(http.StatusOK, "OK")
	})
	e.GET("/:path1/:path2/:path3", func(c echo.Context) error {
		return c.String(http.StatusOK, "OK")
	})
	e.GET("/:path1/:path2/:path3/:path4", func(c echo.Context) error {
		return c.String(http.StatusOK, "OK")
	})
	e.Logger.Fatal(e.Start(":8000"))
}
