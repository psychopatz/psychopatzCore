import java.nio.file.*;
import java.nio.charset.StandardCharsets;
import java.io.Reader;
import java.lang.reflect.*;
import java.util.HashMap;

/** Invoke the installed Project Zomboid Kahlua LuaCompiler; never execute Lua. */
public final class KahluaSyntaxProbe {
    public static void main(String[] args) throws Exception {
        Class<?> kahluaTable = Class.forName("se.krka.kahlua.vm.KahluaTable");
        Object env = Class.forName("se.krka.kahlua.j2se.KahluaTableImpl")
            .getConstructor(java.util.Map.class).newInstance(new HashMap<>());
        Method compile = Class.forName("se.krka.kahlua.luaj.compiler.LuaCompiler")
            .getMethod("loadis", Reader.class, String.class, kahluaTable);
        int compiled = 0;
        for (String arg : args) {
            Path file = Path.of(arg);
            try (Reader reader = Files.newBufferedReader(file, StandardCharsets.UTF_8)) {
                compile.invoke(null, reader, "@" + file, env);
                compiled++;
            } catch (InvocationTargetException error) {
                System.err.println("KAHLUA_FAIL " + file + " " + error.getCause());
                System.exit(2);
            }
        }
        System.out.println("KAHLUA_COMPILED " + compiled);
    }
}
