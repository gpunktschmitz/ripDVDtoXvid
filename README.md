# ripDVDtoXvid

## description
this script rips a dvd to a target folder and sends an email when done/failed

## requirements
* mencoder
* postfix or suchlike (itf you want to send mails when ripping has finished/failed)

## usage
run the script and pass a mount point 
```bash
  ripDVDtoXvid /media/DVDname
```

or you may set it as default action when a DVD movie is inserted into your DVD drive [like i did on gnome](http://gpunktschmitz.de/linux-mint-ubuntu/689-bash-script-to-rip-a-dvd-to-xvid-auto-rip-when-insert-media-gnome)
