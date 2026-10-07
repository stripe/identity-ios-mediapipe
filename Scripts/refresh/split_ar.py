import sys, os, struct
# Unique filenames preserve archive members with duplicate names.
path, outdir = sys.argv[1], sys.argv[2]
os.makedirs(outdir, exist_ok=True)
data = open(path, "rb").read()
assert data[:8] == b"!<arch>\n", "not an ar archive"
pos, index = 8, 0
while pos + 60 <= len(data):
    hdr = data[pos:pos+60]
    name = hdr[0:16].decode().strip()
    size = int(hdr[48:58].decode().strip())
    pos += 60
    body = data[pos:pos+size]
    pos += size + (size % 2)
    if name.startswith("#1/"):
        n = int(name[3:])
        name = body[:n].rstrip(b"\0").decode()
        body = body[n:]
    if name.startswith("__.SYMDEF"):
        continue
    out = os.path.join(outdir, "%05d_%s" % (index, os.path.basename(name)))
    open(out, "wb").write(body)
    print("%s\t%s" % (out, os.path.basename(name)))
    index += 1
