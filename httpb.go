package main

import (
    "net/http"
    "time"
    "flag"
    "fmt"
)

var n = flag.Int("n", 1000, "number of requests")

func get(url string, ch chan bool) {
    _, err := http.Get(url)
    if err != nil {
        ch <- false
    } else {
        ch <- true
    }
}

func sequential(n int) {
    success, failed := 0, 0
    start := time.Now()
    for i := 0; i < n; i++ {
        _, err := http.Get("http://127.0.0.1/")
        if err != nil {
            failed += 1
        } else {
            success += 1
        }
    }
    end := time.Now()
    fmt.Printf("sequential: %f\n", end.Sub(start).Seconds())
    fmt.Printf("  success: %d, failed: %d\n", success, failed)
}

func parallel(n int) {
    ch := make(chan bool)
    success, failed := 0, 0
    start := time.Now()
    for i := 0; i < n; i++ {
        go get("http://localhost/", ch)
    }
    for i := 0; i < n; i++ {
        if <- ch {
            success += 1
        } else {
            failed += 1
        }
    }
    end := time.Now()
    fmt.Printf("parallel: %f\n", end.Sub(start).Seconds())
    fmt.Printf("  success: %d, failed: %d\n", success, failed)
}

func main() {
    flag.Parse()
    sequential(*n)
    parallel(*n)
}
