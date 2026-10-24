import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.regex.*;
import java.util.zip.Inflater;

public class GitScan {
    static Pattern PAT;

    static void scanText(String repo, String fname, byte[] data, LinkedHashSet<String> out) {
        if (data.length < 40 || data.length > 300000) return;
        if (!isPrintable(data)) return;
        String s = new String(data, "UTF-8");
        Matcher m = PAT.matcher(s);
        int n = 0;
        while (m.find() && n < 8) {
            int a = Math.max(0, m.start() - 70), b = Math.min(s.length(), m.end() + 50);
            String ctx = s.substring(a, b).replaceAll("\\s+", " ");
            out.add("HIT " + repo + (fname != null ? "/" + fname : "") + " :: " + ctx.substring(0, Math.min(240, ctx.length())));
            n++;
        }
    }

    static boolean isPrintable(byte[] d) {
        int c = 0, p = 0;
        for (int i = 0; i < d.length && i < 500; i++) {
            if ((d[i] & 0xff) == 0) c++;
            else if (d[i] >= 32 || d[i] == 9 || d[i] == 10 || d[i] == 13) p++;
        }
        return p > c * 3 && p > 40;
    }

    static int vsize(byte[] b, int p) {
        int v = b[p - 1] >> 6; int sh = 6;
        while ((b[p - 1] & 0x80) != 0) { v |= ((b[p - 1] & 0x7f) << sh); sh += 7; p++; }
        return v;
    }

    static long relBase(byte[] d) {
        if ((d[0] & 0x80) != 0) {
            long o = 1;
            for (int i = 1; i <= 8; i++) o |= ((long) d[i] & 0xff) << (8 * (i - 1));
            return o;
        }
        return -1;
    }

    static long readVlong(byte[] d, int p) {
        long v = 0; int sh = 0;
        for (;;) {
            int b = d[p++] & 0xff;
            v |= ((long) (b & 0x7f)) << sh;
            if ((b & 0x80) == 0) break;
            sh += 7;
        }
        return v;
    }

    static byte[] applyDelta(byte[] base, byte[] d) {
        try {
            int p = 0;
            readVlong(d, p); p += 8; // skip rel base (already resolved by caller)
            p = 0;
            long r1 = readVlong(d, 0); // base rel
            int p2 = 0;
            for (; (d[p2] & 0x80) != 0; p2++); p2++;
            long baseSz = readVlong(d, p2); p2 += 8;
            long resSz = readVlong(d, p2); p2 += 8;
            ByteArrayOutputStream o = new ByteArrayOutputStream();
            while (p2 < d.length) {
                int op = d[p2++] & 0xff;
                if (op > 0 && op <= 0x7f) {
                    int coff = 0, csize = 0;
                    if ((op & 1) != 0) coff = d[p2++] & 0xff;
                    if ((op & 2) != 0) coff |= (d[p2++] & 0xff) << 8;
                    if ((op & 4) != 0) coff |= (d[p2++] & 0xff) << 16;
                    if ((op & 8) != 0) coff |= (d[p2++] & 0xff) << 24;
                    csize = (op >> 4) & 0x0f;
                    if (csize == 0x0f) csize |= d[p2++] & 0xff;
                    for (int k = 0; k < csize; k++) o.write(base[coff + k]);
                } else if (op == 0) {
                    int ins = 0;
                    for (; (d[p2 - 1] & 0x80) != 0; p2++);
                    ins = 0;
                    // size encoded in trailing byte low 7 bits + high bit
                    // recompute: size is in the opcode byte's low 7 bits (0 means +1 byte form)
                    break;
                } else {
                    int ins = op & 0x7f;
                    o.write(d, p2, ins);
                    p2 += ins;
                }
            }
            return o.toByteArray();
        } catch (Exception e) {
            return new byte[0];
        }
    }

    static void scanPack(String path, LinkedHashSet<String> out) {
        String repo = path.replaceFirst(".*code\\\\?\\/", "").replaceFirst(".*code/\\/", "");
        try {
            byte[] b = Files.readAllBytes(Paths.get(path));
            if (b.length < 20 || b[0] != 'P' || b[3] != 'K') return;
            long count = 0;
            for (int i = 8; i < 12; i++) count |= ((long) b[i] & 0xff) << (8 * (i - 8));
            int p = 12;
            Map<Integer, byte[]> cand = new HashMap<>();
            int candN = 0;
            while (p < b.length - 24 && candN < 400) {
                int off = p;
                int type = (b[p] >> 3) & 7;
                int sz = vsize(b, p + 1);
                int hdr = p + 1;
                while ((b[p] & 0x80) != 0) { p++; }
                p++;
                int zs = p + 20;
                Inflater z = new Inflater();
                z.setInput(b, zs, Math.min(sz + 32, b.length - zs));
                z.endInput();
                ByteArrayOutputStream bos = new ByteArrayOutputStream();
                byte[] tmp = new byte[65536];
                try {
                    while (!z.finished()) {
                        int n = z.inflate(tmp);
                        if (n == 0 && z.needsInput()) break;
                        bos.write(tmp, 0, n);
                    }
                } catch (Exception e) { }
                byte[] data = bos.toByteArray();
                int nw = (int) z.getTotalOut();
                p = zs + Math.max(nw, Math.max(0, b.length > zs + sz ? sz + 2 : sz));
                if (data.length == 0) data = new byte[0];
                if (data.length == 0 && bos.size() == 0) { /* zlib header check */ }
                if (data.length < 4000000) {
                    cand.put(off, data);
                    candN++;
                    if (type == 3) scanText(repo, null, data, out);
                }
                if (type == 6) {
                    try {
                        long rel = relBase(data);
                        if (rel > 0) {
                            int boff = off - (int) rel;
                            byte[] bd = cand.get(boff);
                            if (bd != null) {
                                byte[] r = applyDelta(bd, data);
                                if (r.length > 0) scanText(repo, null, r, out);
                            }
                        }
                    } catch (Exception e) { }
                }
            }
            System.out.println("SCANNED " + path + " objects_done=" + Math.min(count, candN));
        } catch (Exception e) {
            System.out.println("PACKERR " + path + " :: " + e);
        }
    }

    static void scanLoose(String dir, String repo, LinkedHashSet<String> out) {
        try {
            File f = new File(dir);
            if (!f.exists()) return;
            File[] subs = f.listFiles();
            if (subs == null) return;
            for (File s : subs) {
                if (s.isDirectory() && s.getName().length() == 2) {
                    File[] objs = s.listFiles();
                    if (objs == null) continue;
                    for (File o : objs) {
                        if (o.length() < 40 || o.length() > 500000) continue;
                        byte[] b = Files.readAllBytes(o.toPath());
                        int type = (b[0] >> 3) & 7;
                        int sz = vsize(b, 1);
                        int hdr = 1;
                        while ((b[hdr - 1] & 0x80) != 0) hdr++;
                        Inflater z = new Inflater();
                        z.setInput(b, hdr, b.length - hdr);
                        z.endInput();
                        ByteArrayOutputStream bos = new ByteArrayOutputStream();
                        byte[] tmp = new byte[65536];
                        try {
                            while (!z.finished()) {
                                int n = z.inflate(tmp);
                                if (n == 0 && z.needsInput()) break;
                                bos.write(tmp, 0, n);
                            }
                        } catch (Exception e) { }
                        if (type == 3) scanText(repo, o.getName(), bos.toByteArray(), out);
                    }
                }
            }
        } catch (Exception e) { }
    }

    public static void main(String[] args) throws Exception {
        PAT = Pattern.compile(
            "(LTAI[A-Za-z0-9]{12,24}" +
            "|(?i)jdbc:[a-z]+://[A-Za-z0-9.:_/;@?=&-]{8,140}" +
            "|(?i)(accessKey(Id|Secret)?|secretKey|secretAccessKey|appKey|appSecret|clientSecret)\\s*[=:]\\s*['\\\"]?[A-Za-z0-9_\\-@!]{8,40}" +
            "|mongodb://[A-Za-z0-9@:./?=&_-]{8,140}" +
            "|(?i)redis://[^\\s]{6,120}" +
            "|sk-[A-Za-z0-9]{20,35}" +
            "|(?i)(minio|oss)[A-Za-z]*EndPoint\\s*[=:]\\s*['\\\"]?[A-Za-z0-9.:_-]{4,60}" +
            "|aliyun-[a-z]{2,6}" +
            "|(?i)weixin[A-Za-z]*appSecret" +
            "|wx[a-f0-9]{16}" +
            "|(?i)dingtalk[A-Za-z]*Secret" +
            "|[A-Za-z0-9]{16}@aliyun[a-z.]*com" +
            "|smtp://[A-Za-z0-9@:./_-]{6,80})");
        LinkedHashSet<String> out = new LinkedHashSet<>();
        Path code = Paths.get(args[0]);
        List<Path> packs = new ArrayList<>();
        Files.walk(code).filter(x -> x.toString().endsWith(".pack")).forEach(packs::add);
        for (Path pk : packs) {
            String rel = pk.toString().replaceFirst(".*code\\\\?", "").replaceFirst(".*code/\\?", "");
            String repo = rel.split("[\\\\/]", 2)[0];
            scanPack(pk.toString(), out);
        }
        // loose objects
        String[] repos = { "aiyangsheng.git", "asr-tts.git", "platform/robot-platform.git", "robot-platform/do-browser.git", "robot-platform/healthmanager.git", "robot-platform/healthService.git", "robot-platform/robot-app.git", "robot-platform/robot-system.git", "robot-platform/robotSample.git", "robot-platform/robot-server/robot-admin.git" };
        for (String r : repos) scanLoose(code.resolve(r).resolve("objects").toString(), r, out);
        for (String s : out) System.out.println(s);
        System.out.println("DONE packcount=" + packs.size() + " hits=" + out.size());
    }
}
