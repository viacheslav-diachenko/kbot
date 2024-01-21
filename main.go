/*
Copyright © 2023 NAME HERE <EMAIL ADDRESS>
*/
package main

import (
	"fmt"
	"github.com/viacheslav-diachenko/telegram_bot/cmd"
)

func main() {
	fmt.Println("Build Version:\t", cmd.AppVersion)
	cmd.Execute()
}
