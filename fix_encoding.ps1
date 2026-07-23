
$f = "lib\features\dashboard\presentation\test_screen_4.dart"
$text = [System.IO.File]::ReadAllText($f, [System.Text.Encoding]::UTF8)

# Windows-1252 byte -> Unicode codepoint mapping for the problematic bytes
# F0=0xF0, 9F=0x178(Ÿ), 80=0x20AC(€), 81=0x81, 82=0x201A(‚), 83=0x192(ƒ), 
# 84=0x201E(„), 85=0x2026(…), 86=0x2020(†), 87=0x2021(‡), 88=0x2C6(ˆ),
# 89=0x2030(‰), 8A=0x160(Š), 8B=0x2039(‹), 8C=0x152(Œ), 8E=0x17D(Ž),
# 91=0x2018('), 92=0x2019('), 93=0x201C("), 94=0x201D("), 95=0x2022(•),
# 96=0x2013(–), 97=0x2014(—), 98=0x2DC(˜), 99=0x2122(™), 9A=0x161(š),
# 9B=0x203A(›), 9C=0x153(œ), 9E=0x17E(ž), 9F=0x178(Ÿ)

# Build the win1252 mapping
$w = @{
    0xF0=[char]0x00F0; 0x9F=[char]0x0178; 0x80=[char]0x20AC; 0x81=[char]0x0081;
    0x82=[char]0x201A; 0x83=[char]0x0192; 0x84=[char]0x201E; 0x85=[char]0x2026;
    0x86=[char]0x2020; 0x87=[char]0x2021; 0x88=[char]0x02C6; 0x89=[char]0x2030;
    0x8A=[char]0x0160; 0x8B=[char]0x2039; 0x8C=[char]0x0152; 0x8E=[char]0x017D;
    0x91=[char]0x2018; 0x92=[char]0x2019; 0x93=[char]0x201C; 0x94=[char]0x201D;
    0x95=[char]0x2022; 0x96=[char]0x2013; 0x97=[char]0x2014; 0x98=[char]0x02DC;
    0x99=[char]0x2122; 0x9A=[char]0x0161; 0x9B=[char]0x203A; 0x9C=[char]0x0153;
    0x9E=[char]0x017E; 0x9F=[char]0x0178;
    # Regular latin-1 range 0xA0-0xFF maps directly
}
for ($i = 0xA0; $i -le 0xFF; $i++) { if (-not $w.ContainsKey($i)) { $w[$i] = [char]$i } }
# Regular ASCII 0x00-0x7F maps directly
for ($i = 0; $i -le 0x7F; $i++) { $w[$i] = [char]$i }

# Convert a corrupted string (sequence of w1252 chars) back to the original UTF-8 bytes
function MojiToBytes([string]$moji) {
    # Each char in moji came from one byte via Win-1252
    # Reverse: find what byte produced each char
    $revMap = @{}
    foreach ($kv in $w.GetEnumerator()) { $revMap[[int]$kv.Value] = $kv.Key }
    $result = [System.Collections.Generic.List[byte]]::new()
    foreach ($c in $moji.ToCharArray()) {
        $cp = [int]$c
        if ($revMap.ContainsKey($cp)) {
            $result.Add([byte]$revMap[$cp])
        } else {
            $result.Add([byte]($cp -band 0xFF))
        }
    }
    return $result.ToArray()
}

# Now define the emoji to fix: (corrupted_moji_string, correct_unicode_string)
$fixes = @(
    # ðŸ"" = 🔔 bell (F0 9F 94 94)
    @{ moji = [string]([char]0xF0) + [char]0x0178 + [char]0x201D + [char]0x201D; correct = [char]::ConvertFromUtf32(0x1F514) },
    # ðŸ'¥ = 👥 people (F0 9F 91 A5)
    @{ moji = [string]([char]0xF0) + [char]0x0178 + [char]0x2018 + [char]0x00A5; correct = [char]::ConvertFromUtf32(0x1F465) },
    # ðŸ'¥ check - people group is F0 9F 91 A5
    # ðŸƒ = 🃏 playing card (F0 9F 83 8F)
    @{ moji = [string]([char]0xF0) + [char]0x0178 + [char]0x0192 + [char]0x008F; correct = [char]::ConvertFromUtf32(0x1F0CF) },
    # ðŸ'' = 👑 crown (F0 9F 91 91)
    @{ moji = [string]([char]0xF0) + [char]0x0178 + [char]0x2018 + [char]0x2018; correct = [char]::ConvertFromUtf32(0x1F451) },
    # ðŸŽ = 🎁 gift (F0 9F 8E 81)
    @{ moji = [string]([char]0xF0) + [char]0x0178 + [char]0x008E + [char]0x201A; correct = [char]::ConvertFromUtf32(0x1F381) },
    # ðŸ'° = 💰 money (F0 9F 92 B0)
    @{ moji = [string]([char]0xF0) + [char]0x0178 + [char]0x201C + [char]0x00B0; correct = [char]::ConvertFromUtf32(0x1F4B0) },
    # ðŸ'Ž = 💎 diamond gem (F0 9F 92 8E)
    @{ moji = [string]([char]0xF0) + [char]0x0178 + [char]0x201C + [char]0x008E; correct = [char]::ConvertFromUtf32(0x1F48E) },
    # ðŸ"¥ = 🔥 fire (F0 9F 94 A5)
    @{ moji = [string]([char]0xF0) + [char]0x0178 + [char]0x201D + [char]0x00A5; correct = [char]::ConvertFromUtf32(0x1F525) },
    # ðŸ† = 🏆 trophy (F0 9F 8F 86)
    @{ moji = [string]([char]0xF0) + [char]0x0178 + [char]0x008F + [char]0x2020; correct = [char]::ConvertFromUtf32(0x1F3C6) },
    # ðŸ›' = 🛍 shopping (F0 9F 9B 8D)
    @{ moji = [string]([char]0xF0) + [char]0x0178 + [char]0x203A + [char]0x008D; correct = [char]::ConvertFromUtf32(0x1F6CD) },
    # ðŸŽ™ = 🎙 mic (F0 9F 8E 99)
    @{ moji = [string]([char]0xF0) + [char]0x0178 + [char]0x008E + [char]0x2122; correct = [char]::ConvertFromUtf32(0x1F399) },
    # ðŸ'¬ = 💬 chat (F0 9F 92 AC)
    @{ moji = [string]([char]0xF0) + [char]0x0178 + [char]0x201C + [char]0x00AC; correct = [char]::ConvertFromUtf32(0x1F4AC) },
    # ðŸŒŸ = 🌟 glowing star (F0 9F 8C 9F)
    @{ moji = [string]([char]0xF0) + [char]0x0178 + [char]0x008C + [char]0x0178; correct = [char]::ConvertFromUtf32(0x1F31F) },
    # ðŸ¥‡ = 🥇 gold medal (F0 9F A5 87)
    @{ moji = [string]([char]0xF0) + [char]0x0178 + [char]0x00A5 + [char]0x2021; correct = [char]::ConvertFromUtf32(0x1F947) },
    # ðŸ'› = 💛 yellow heart (F0 9F 92 9B)
    @{ moji = [string]([char]0xF0) + [char]0x0178 + [char]0x201C + [char]0x203A; correct = [char]::ConvertFromUtf32(0x1F49B) },

    # 3-byte sequences
    # â™  = ♠ spade (E2 99 A0)
    @{ moji = [string]([char]0x00E2) + [char]0x2122 + [char]0x00A0; correct = [char]0x2660 },
    # â™¥ = ♥ heart (E2 99 A5)
    @{ moji = [string]([char]0x00E2) + [char]0x2122 + [char]0x00A5; correct = [char]0x2665 },
    # â™£ = ♣ club (E2 99 A3)
    @{ moji = [string]([char]0x00E2) + [char]0x2122 + [char]0x00A3; correct = [char]0x2663 },
    # â™¦ = ♦ diamond (E2 99 A6)
    @{ moji = [string]([char]0x00E2) + [char]0x2122 + [char]0x00A6; correct = [char]0x2666 },
    # â˜° = ☰ menu (E2 98 B0)
    @{ moji = [string]([char]0x00E2) + [char]0x02DC + [char]0x00B0; correct = [char]0x2630 },
    # â•' = ══ double bar (E2 95 90)
    @{ moji = [string]([char]0x00E2) + [char]0x2022 + [char]0x2019; correct = [char]0x2550 },
    # â€¢ = • bullet (E2 80 A2)
    @{ moji = [string]([char]0x00E2) + [char]0x20AC + [char]0x00A2; correct = [char]0x2022 },
    # â†' = → arrow (E2 86 92)
    @{ moji = [string]([char]0x00E2) + [char]0x20AC + [char]0x2019; correct = [char]0x2019 },  # right single quote first
    # â€" = – en dash (E2 80 93)
    @{ moji = [string]([char]0x00E2) + [char]0x20AC + [char]0x201C; correct = [char]0x201C }, # left double quote (already correct)
    # ✦ = ✦ (E2 9C A6)
    @{ moji = [string]([char]0x00E2) + [char]0x0153 + [char]0x00A6; correct = [char]0x2726 },
    # â˜… = ★ (E2 98 85)
    @{ moji = [string]([char]0x00E2) + [char]0x02DC + [char]0x2026; correct = [char]0x2605 },
    # â–¶ = ▶ (E2 96 B6)
    @{ moji = [string]([char]0x00E2) + [char]0x2013 + [char]0x00B6; correct = [char]0x25B6 }
)

$count = 0
foreach ($fix in $fixes) {
    $before = $text
    $text = $text.Replace($fix.moji, $fix.correct)
    if ($text -ne $before) {
        $count++
        Write-Host "Fixed: -> $($fix.correct)"
    }
}

Write-Host "Total replacements: $count"
[System.IO.File]::WriteAllText($f, $text, (New-Object System.Text.UTF8Encoding $false))
Write-Host "Saved."
