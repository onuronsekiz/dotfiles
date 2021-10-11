# dotfiles
awesomewm, alacritty, rofi, ranger, vim config files for voidlinux.

config for awesomewm is heavily modified version of another user. 
alacrity, rofi and mocp designs are mine.

support for both single screen and multi screens with different resolutions.

near all bar elements have tooltips on them triggered with mouse:enter.

Feel free to copy them.

Requirements
- music widget         : mocp
- logout widget        : polkit rule or sudoers for poweroff, reboot, zzz
- disk mount/unmount   : udisks2 (with polkit rule)
- volume widget        : pulsemixer + alsautils
- net widget           : wget (for public ip, can be changed with curl)
- shortcut tool        : xdotool (for onboard keyboard)
- theming              : qt5ct + lxappearance (optional)

Other requirements like terminal, browser, filemanager can be changed through `rc.lua` and `theme.lua` according to your taste.
DON'T FORGET TO CHANGE `loadkeys` language in `.xprofile` according to your language.

![2021-10-11_01-22](https://user-images.githubusercontent.com/76511536/136715002-1e41b69c-f634-48dd-b2c6-a4cbf2688385.png)

![2021-10-11_03-46](https://user-images.githubusercontent.com/76511536/136719105-a091e9e1-4cea-4d01-afd4-76cfa61f9b0b.png)

![2021-10-12_02-12](https://user-images.githubusercontent.com/76511536/136866235-e48ad7be-bfbe-43e9-a696-d241ba62d237.png)

![2021-10-12_02-17](https://user-images.githubusercontent.com/76511536/136866239-20c44351-d564-4841-a37a-0641ca1e7a45.png)

![2021-10-11_03-44](https://user-images.githubusercontent.com/76511536/136719008-8632ef68-0c8e-4d35-8275-39772e8d01bc.png)
