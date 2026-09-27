import ctypes, os, struct, sys, time
libc=ctypes.CDLL("libc.so.6", use_errno=True)
fd=libc.inotify_init()
M={0x2:"MODIFY",0x8:"CLOSE_WRITE",0x40:"MOVED_FROM",0x80:"MOVED_TO",0x100:"CREATE",0x200:"DELETE",0x400:"DELETE_SELF",0x800:"MOVE_SELF",0x4:"ATTRIB"}
d=sys.argv[1]; libc.inotify_add_watch(fd, d.encode(), 0xFFF)
os.set_blocking(fd, False); end=time.time()+float(sys.argv[2])
while time.time()<end:
    try: buf=os.read(fd,65536)
    except BlockingIOError: time.sleep(0.05); continue
    i=0
    while i<len(buf):
        wd,mask,cookie,ln=struct.unpack_from("iIII",buf,i); name=buf[i+16:i+16+ln].rstrip(b"\0").decode()
        if not name.startswith(("probe","tiled.out")): print(name, "|".join(v for k,v in M.items() if mask&k), flush=True)
        i+=16+ln
