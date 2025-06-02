output image {
  value = {
    linux = {
      version = "9.5.202411260"
      x64 = {
        publisher = "AlmaLinux"
        offer     = "AlmaLinux-x86_64"
        sku       = "9-Gen2"
      }
      arm = {
        publisher = "AlmaLinux"
        offer     = "AlmaLinux-ARM"
        sku       = "9-ARM-Gen2"
      }
    }
    windows = {
      version = "Latest"
      cluster = {
        enable = false
      }
    }
  }
}
