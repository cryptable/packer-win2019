
# VM Section
# ----------

variable "autounattend" {
  type    = string
  default = "./scripts/Autounattend.xml"
}

variable "disk_size" {
  type    = string
  default = "60G"
}

variable "disk_type_id" {
  type    = string
  default = "1"
}

variable "headless" {
  type    = string
  default = "false"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:549bca46c055157291be6c22a3aaaed8330e78ef4382c99ee82c896426a1cee1"
}

variable "memory" {
  type    = string
  default = "2048"
}

variable "cpu" {
  type    = string
  default = "2"
}

variable "restart_timeout" {
  type    = string
  default = "5m"
}

variable "vm_name" {
  type    = string
  default = "windows10"
}

variable "vmx_version" {
  type    = string
  default = "14"
}

variable "winrm_timeout" {
  type    = string
  default = "6h"
}

# WMware Section
# --------------

variable "iso_url" {
  type    = string
  default = "./assets/17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us_1.iso"
}

# Proxmox Section
# ---------------

variable "pve_username" {
  type    = string
  default = "root"
}

variable "pve_token" {
  type    = string
  default = "secret"
}

variable "pve_url" {
  type    = string
  default = "https://127.0.0.1:8006/api2/json"
}

variable "iso_file"  {
  type    = string
  default = "local:iso/17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us_1.iso"
}

variable "vm_id" {
  type    = string
  default = "9000"
}

source "vmware-iso" "windows2019" {
  boot_wait         = "2m"
  communicator      = "winrm"
  cpus              = 2
  disk_adapter_type = "lsisas1068"
  disk_size         = "${var.disk_size}"
  disk_type_id      = "${var.disk_type_id}"
  floppy_files      = [
    "${var.autounattend}", 
    "./scripts/disable-screensaver.ps1", 
    "./scripts/disable-winrm.ps1", 
    "./scripts/enable-winrm.ps1", 
    "./scripts/microsoft-updates.bat", 
    "./scripts/unattend.xml", 
    "./scripts/sysprep.bat", 
    "./scripts/win-updates.ps1"
  ]
  guest_os_type     = "windows9srv-64"
  headless          = "${var.headless}"
  iso_checksum      = "${var.iso_checksum}"
  iso_url           = "${var.iso_url}"
  memory            = "${var.memory}"
  shutdown_command  = "a:/sysprep.bat"
  version           = "${var.vmx_version}"
  vm_name           = "WindowsServer2019"
  vmx_data = {
    "RemoteDisplay.vnc.enabled" = "false"
    "RemoteDisplay.vnc.port"    = "5900"
  }
  vmx_remove_ethernet_interfaces = true
  vnc_port_max                   = 5980
  vnc_port_min                   = 5900
  winrm_password                 = "vagrant"
  winrm_timeout                  = "${var.winrm_timeout}"
  winrm_username                 = "vagrant"
  format = "ova"
}

# Proxmox image section
# ---------------------

source "proxmox-iso" "windows2019" {
  proxmox_url = "${var.pve_url}"
  username = "${var.pve_username}"
  token = "${var.pve_token}"
  node =  "pve"
  iso_checksum = "${var.iso_checksum}"
  iso_file = "${var.iso_file}"
  insecure_skip_tls_verify = true
  boot_command      = [ "" ]
  boot_wait         = "6m"
  communicator      = "winrm"
  winrm_password    = "vagrant"
  winrm_timeout     = "${var.winrm_timeout}"
  winrm_username    = "vagrant"
  cores             = "${var.cpu}"
  memory            = "${var.memory}"
  vm_name           = "${var.vm_name}"
  vm_id             = "${var.vm_id}"
  os                = "win10"
  network_adapters {
    model = "virtio"
    bridge = "vmbr0"
  }
  scsi_controller = "virtio-scsi-pci"
  disks {
    type = "scsi"
    disk_size  = "${var.disk_size}"
    storage_pool = "local-lvm"
    storage_pool_type = "lvm-thin"
    format = "raw"
  }
  additional_iso_files  {
    device= "sata1"
    iso_file= "local:iso/virtio-win-0.1.215.iso"
    iso_checksum= "b9d8442c53e2383b60e49905a9e5911419a253c6a1838be3ea90c7209b26b5d7"
    unmount= true
  }
  additional_iso_files {
    device= "sata2"
    iso_file= "local:iso/Autounattend-win2019.iso"
    iso_checksum= "90314d7ef95f27f6b705d9d1a4adba360dcf763266757a69f383eaf2a62858b3"
    unmount= true
  }
  template_name = "${var.vm_name}"
  template_description = "Windows 10 template"
}


build {
  sources = [
    "source.vmware-iso.windows2019",
    "source.proxmox-iso.windows2019"
  ]

  provisioner "windows-shell" {
    execute_command = "{{ .Vars }} cmd /c \"{{ .Path }}\""
    scripts         = [
      "./scripts/enable-rdp.bat"
    ]
  }

  provisioner "powershell" {
    scripts = [
      "./scripts/vm-guest-tools.ps1"
    ]
    only = [ 
      "vmware-iso.windows10", 
      "null.vagrant" 
    ]

  }

  provisioner "windows-restart" {
    restart_timeout = "${var.restart_timeout}"
  }

  provisioner "windows-shell" {
    execute_command = "{{ .Vars }} cmd /c \"{{ .Path }}\""
    scripts         = [
      "./scripts/compile-dotnet-assemblies.bat", 
      "./scripts/set-winrm-automatic.bat", 
      "./scripts/uac-enable.bat"
    ]
  }

 provisioner "powershell" {
    scripts = [
      "./scripts/win-updates.ps1"
    ]
  }

  provisioner "file" {
    source = "./docs/02_Install_DC1.md"
    destination = "C:\\Users\\vagrant\\Desktop"
  }
  
  provisioner "file" {
    source = "./docs/05_Install_RootCA.md"
    destination = "C:\\Users\\vagrant\\Desktop"
  }

#  post-processor "vagrant" {
#    keep_input_artifact  = true
#    output               = "./output-windows2019/windows_2019_vmware.box"
#  }

}
