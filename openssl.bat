rem this serves as placeholder documentation for now
cd libs\openssl
perl Configure VC-WIN64A enable-static-engine --prefix=c:\code\deps64
ms\do_win64a.bat
nmake -f ms\ntdll.mak
nmake -f ms\ntdll.mak install