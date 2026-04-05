<?php
function generateJunk($length) {
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789&:$£‘!/|\\@#^*_~`";
    $s = "";
    for ($i = 0; $i < $length; $i++) {
        $s .= $chars[rand(0, strlen($chars)-1)];
    }
    return $s;
}

function generateFuncName() {
    $base = ["GG$£", "G£G$", "£GG$", "$G£G", "G$G£", "£$GG"];
    return $base[array_rand($base)] . generateJunk(8);
}

function encryptStr($str) {
    $key = 0xA7;
    $out = [];
    for ($i = 0; $i < strlen($str); $i++) {
        $b = ord($str[$i]);
        $b = (($b ^ $key) + ($i * 5)) % 256;
        $out[] = $b;
    }
    return "string.char(" . implode(",", $out) . ")";
}

function obfuscateCode($source, $level) {
    if (empty($source)) return "-- 코드를 입력하세요";

    $junkSize = ($level == 'extreme') ? 55 : (($level == 'strong') ? 42 : 32);
    $trollMsg = ($level == 'extreme') 
        ? 'print("이거 못풀어 개시발병신새끼야")' 
        : 'print("Good you’re fuck bro")';

    $source = preg_replace_callback('/function\s+([a-zA-Z0-9_]+)/', function($m) {
        return "function " . generateFuncName();
    }, $source);

    $source = preg_replace_callback('/local\s+([a-zA-Z0-9_]+)/', function($m) use ($junkSize) {
        return "local " . generateJunk($junkSize);
    }, $source);

    $source = preg_replace_callback('/"([^"]*)"/', function($m) {
        return encryptStr($m[1]);
    }, $source);

    $source = preg_replace_callback("/'([^']*)'/", function($m) {
        return encryptStr($m[1]);
    }, $source);

    $junk = "\nlocal " . generateJunk($junkSize + 10) . " = " . rand(10000000, 99999999) . "\n";

    $final = "-- 3중 난독화 + Troll 보호 by 시우 (" . strtoupper($level) . " 모드)\n" .
             $junk .
             "if debug.getinfo or hookfunction or getgc or getrenv or string.dump then\n" .
             "    " . $trollMsg . "\n" .
             "    return\n" .
             "end\n\n" .

             $source . "\n\n" .
             $junk;

    if ($level == 'extreme') {
        $final .= "\nwhile true do end\n";
    }

    return $final;
}

$original = $_POST['code'] ?? '';
$level = $_POST['level'] ?? 'normal';
$obfuscated = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && !empty($original)) {
    $obfuscated = obfuscateCode($original, $level);
}
?>

<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>시우의 Roblox Luau 3중 난독화기</title>
    <style>
        body { font-family: Arial, sans-serif; background: #121212; color: #eee; padding: 30px; }
        .container { max-width: 1200px; margin: auto; }
        textarea { width: 100%; height: 320px; background: #1e1e1e; color: #0f0; border: 2px solid #444; padding: 15px; font-family: monospace; font-size: 15px; }
        select, button { padding: 12px 18px; margin: 8px 5px; font-size: 16px; border: none; border-radius: 4px; cursor: pointer; }
        .obf-btn { background: #ff3333; color: white; font-weight: bold; }
        .copy-btn { background: #22cc22; color: white; font-weight: bold; }
        #result { background: #1a1a1a; padding: 18px; border: 2px solid #555; white-space: pre-wrap; font-family: monospace; font-size: 14px; margin-top: 15px; min-height: 320px; line-height: 1.4; }
        label { margin-right: 10px; font-weight: bold; }
    </style>
</head>
<body>
<div class="container">
    <h1>시우의 Roblox Luau 3중 난독화기</h1>
    <p>강도 선택 후 난독화하세요.<br>
       <strong>극강 모드</strong>에서는 deobfuscator로 풀려고 하면 <strong>"이거 못풀어 개시발병신새끼야"</strong>만 뜹니다.</p>

    <form method="POST">
        <label for="level">난독화 강도 선택:</label>
        <select name="level" id="level">
            <option value="normal" <?= $level=='normal'?'selected':'' ?>>기본</option>
            <option value="strong" <?= $level=='strong'?'selected':'' ?>>강력</option>
            <option value="extreme" <?= $level=='extreme'?'selected':'' ?>>극강</option>
        </select><br><br>

        <textarea name="code" placeholder="여기에 원본 Luau 스크립트를 붙여넣으세요..."><?= htmlspecialchars($original) ?></textarea><br>
        <button type="submit" class="obf-btn">난독화하기</button>
    </form>

    <?php if ($obfuscated): ?>
    <h2>✅ 난독화 완료 (<?= strtoupper($level) ?> 모드)</h2>
    <div id="result"><?= htmlspecialchars($obfuscated) ?></div>
    <button onclick="copyToClipboard()" class="copy-btn">복사하기</button>
    <?php endif; ?>
</div>

<script>
function copyToClipboard() {
    const text = document.getElementById('result').innerText;
    navigator.clipboard.writeText(text).then(() => {
        alert('✅ 난독화된 코드가 클립보드에 복사되었습니다!');
    }).catch(() => {
        alert('복사 실패했습니다. 직접 드래그해서 복사하세요.');
    });
}
</script>
</body>
</html>
