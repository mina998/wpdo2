# RC红色错误  GC绿色成功  LG浅绿输出  BC蓝色输入  SB天蓝确认  CC橙色提示  PC粉色强调
RC="\033[38;5;196m"; RR="\033[31m"; GC="\033[38;5;82m"; LG="\033[38;5;72m"; BC="\033[39;1;34m"; SB="\033[38;5;45m"
CC="\033[38;5;208m"; PC="\033[38;5;201m"; YC="\033[38;5;148m"; ED="\033[0m";

# 红色错误
function echoRC {
    echo -e "$RC${1}$ED"
}
# 玫红
function echoRR {
    echo -e "$RR${1}$ED"
}
# 绿色成功
function echoGC {
    echo -e "$GC${1}$ED"
}
# 浅绿输出
function echoLG {
    echo -e "$LG${1}$ED"
}
# 天蓝
function echoBC {
    echo -e "$BC${1}$ED"
}
# SB
function echoSB {
    echo -e "$SB${1}$ED"
}
# 橙色提示
function echoCC {
    echo -e "$CC${1}$ED"
}
# PC粉色
function echoPC {
    echo -e "$PC${1}$ED"
}
# 黄色
function echoYC {
    echo -e "$YC${1}$ED"
}