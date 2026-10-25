param([Parameter(Mandatory=$true)][string]$Path)
$ErrorActionPreference = 'Stop'
$assembly = [Reflection.Assembly]::ReflectionOnlyLoad([IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Path)))
foreach ($reference in $assembly.GetReferencedAssemblies()) { if ($reference.Name -in @('mscorlib','System','System.Core','System.Windows.Forms','System.Drawing')) { [void][Reflection.Assembly]::ReflectionOnlyLoad($reference.FullName) } }
$opcodes = @{}
[Reflection.Emit.OpCodes].GetFields([Reflection.BindingFlags]'Public,Static') | ForEach-Object { $op = $_.GetValue($null); $opcodes[[int]$op.Value -band 65535] = $op }
foreach ($type in $assembly.GetTypes()) {
  foreach ($method in @($type.GetMethods([Reflection.BindingFlags]'Public,NonPublic,Static,Instance,DeclaredOnly')) + @($type.GetConstructors([Reflection.BindingFlags]'Public,NonPublic,Static,Instance,DeclaredOnly'))) {
    $body = $method.GetMethodBody()
    if (!$body) { continue }
    'METHOD {0}::{1} TOKEN 0x{2:x8}' -f $type.FullName,$method.Name,$method.MetadataToken
    $bytes = $body.GetILAsByteArray(); $position = 0
    while ($position -lt $bytes.Length) {
      $offset = $position; $value = [int]$bytes[$position]; $position++
      if ($value -eq 254) { $value = 65024 + [int]$bytes[$position]; $position++ }
      $op = $opcodes[$value]; if (!$op) { throw ('Unknown opcode at '+$offset) }
      $operand = ''; $count = 0; $token = 0
      switch ($op.OperandType.ToString()) {
        InlineNone { }
        ShortInlineI { $operand = [int][sbyte]($bytes[$position] -band 127) - 128 * [int](($bytes[$position] -band 128) -ne 0); $count=1 }
        InlineI { $operand = [BitConverter]::ToInt32($bytes,$position); $count=4 }
        InlineI8 { $operand = [BitConverter]::ToInt64($bytes,$position); $count=8 }
        ShortInlineR { $operand = [BitConverter]::ToSingle($bytes,$position); $count=4 }
        InlineR { $operand = [BitConverter]::ToDouble($bytes,$position); $count=8 }
        ShortInlineVar { $operand = $bytes[$position]; $count=1 }
        InlineVar { $operand = [BitConverter]::ToUInt16($bytes,$position); $count=2 }
        ShortInlineBrTarget { $delta = [int]$bytes[$position]; if ($delta -ge 128) {$delta-=256}; $operand = 'IL_{0:x4}' -f ($position+1+$delta); $count=1 }
        InlineBrTarget { $operand = 'IL_{0:x4}' -f ($position+4+[BitConverter]::ToInt32($bytes,$position)); $count=4 }
        InlineSwitch { $n=[BitConverter]::ToInt32($bytes,$position); $count=4+4*$n; $operand='switch '+$n }
        default {
          $token=[BitConverter]::ToInt32($bytes,$position); $count=4
          try { if ($op.OperandType.ToString() -eq 'InlineString') {$operand='"'+$method.Module.ResolveString($token)+'"'} else {$operand=$method.Module.ResolveMember($token).ToString()} } catch { $operand='TOKEN 0x{0:x8}' -f $token }
        }
      }
      '  IL_{0:x4}: {1} {2}' -f $offset,$op.Name,$operand
      $position += $count
    }
  }
}
