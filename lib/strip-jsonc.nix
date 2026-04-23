{ lib }:

text:
let
  lines = lib.splitString "\n" text;

  findCommentPos =
    line:
    let
      len = lib.stringLength line;
      go =
        pos: quotes:
        if pos >= len - 1 then
          null
        else
          let
            c = lib.substring pos 1 line;
            next = lib.substring (pos + 1) 1 line;
            newQuotes = quotes + (if c == "\"" then 1 else 0);
          in
          if c == "/" && next == "/" && lib.mod newQuotes 2 == 0 then pos else go (pos + 1) newQuotes;
    in
    go 0 0;

  stripLine =
    line:
    let
      pos = findCommentPos line;
    in
    if pos == null then line else lib.substring 0 pos line;
in
lib.concatStringsSep "\n" (map stripLine lines)
