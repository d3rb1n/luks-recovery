# luks-recovery

Source for bash scripts to recover a lost LUKS disk encryption password (if you have solid guesses on what it might be).

When I went to start up my security research work again, I realized that I didn't remember my LUKS disk encryption password. I know it was VERY likely going to one of a few schemes. So, I tried several guesses. On this machine:

* I could try 5 times, and then it reset the prompt once.
* After 5 additional tries, it dumps me out at a Grub prompt. You then need to reboot to try again.

So, it was not the obvious guesses, but I was still quite sure it would be some derivation. I did a little research into cracking LUKS, and it gets fairly involved. Also, I was thinking: if I could just brute-force this with a combination of elements, I'm sure I could "guess" it.

## STEP 1: Booting into a Live Linux distribution

I use [Zorin OS](https://zorin.com/os/) as my primary Linux distribution for personal use, and I had a USB that has the installer + Live, so I booted into that. That at least gives me a windowed Linux environment.

## STEP 2: Generate a "wordlist"

In my case, I was pretty sure there might be up to three elements to the password.

> [!TIP] TIP: Creating complex, but easy-to-remember passwords
> 
> For passwords that you need to remember, one way to do this is to have a song lyric or movie quote. One example is: "Houston, we have a problem". I might turn that into "Houston, we have a damn problem", which turns into "Houston, we have a !@#$ problem!". Then, just pull out the first letters, and keep the symbols and you get: `Hwha!@#$p!` as a "core" element of a password.

For example:

> [Year][ServiceName][CoreElement]

Meaning that it might be: `2024Q3LUKSHwha#$%^p!`

So, my thought was to have three files that represent those elements, then write a script to combine every combination. For example:

> [!NOTE] FILE: source1.txt
> ```text
>   
> 24
> 2024
> 23
> 2023
> 22
> 2022
> ```

> [!NOTE] FILE: source2.txt
> ```text
>   
> LUKS
> luks
> DISK
> ```

> [!NOTE] FILE: source3.txt
> ```text
>   
> Hwha!@#$p!
> Password
> Pass
> password
> pass
> ```

and running this script would create a wordlist file that has every combination of each line from those 3 files, like:

> [!NOTE] FILE: wordlist.txt
> ```text
>   
> 24
> 2024
> 23
> 2023
> LUKS
> LUKS24
> LUKS2024
> LUKS23
> LUKS2023
> luks
> luks24
> luks2024
> luks23
> luks2023
> DISK
> DISK24
> DISK2024
> DISK23
> DISK2023
> Hwha!@#$p!
> Hwha!@#$p!24
> Hwha!@#$p!2024
> Hwha!@#$p!23
> Hwha!@#$p!2023
> Hwha!@#$p!LUKS
> Hwha!@#$p!LUKS24
> etc...
> ```

If you have 4 or 5 "elements" to your password, this could be expanded obviously.

## STEP 3: Try the wordlist passwords on LUKS

Finally, have a script that would take each line of the wordlist and try that as a LUKS password.

### Find the primary LUKS partition

In my case `/dev/nvme0n1` was my primary disk, and it had three partitions on it. You can run something like this to see if it's a LUKS partition:

```bash
sudo cryptsetup luksDump /dev/nvme0n1p2
```

If it's not, you'll see:

```bash
Device /dev/nvme0n1p2 is not a valid LUKS device.
```

But if it is, you'll see a bunch of output like:

```bash
LUKS header information
Version:        2
Epoch:          3
Metadata area:  16384 [bytes]
Keyslots area:  16744448 [bytes]
UUID:           9e44bcc9-94f1-415f-b41b-3b5edd0ff96c
Label:          (no label)
Subsystem:      (no subsystem)
Flags:          (no flags)

Data segments:
  0: crypt
        offset: 16777216 [bytes]
        length: (whole device)
        cipher: aes-xts-plain64
etc...
```

Once we know which partition it is, we can "try" a password with:

```bash
echo "2024Q3LUKSHwhap" | cryptsetup luksOpen /dev/nvme0n1p3 my_luks_volume --test-passphrase
```

This returns `0` if the passphrase is correct, and non-zero if it's not correct.

As you might imagine, you can now put all of this together into a few scripts to automate. See the next [src/README.md](src/README.md) for detail on those scripts.