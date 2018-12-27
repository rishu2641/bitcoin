defmodule Helper do
    def gen_zero_string(s,n) do
        hash = :crypto.hash(:sha256, s <> ";" <> Integer.to_string(n)) |> Base.encode16()
        if String.slice(hash, 0, 2)  == "00" do
            [n, hash]
        else
            gen_zero_string(s,n+1)
        end
    end
end