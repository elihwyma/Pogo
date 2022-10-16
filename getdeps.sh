cd Pogo/Required
if [ -f substitute.deb ]; then
    echo "Dependencies already downloaded"
    exit 0
fi
curl -sLO https://github.com/coolstar/Odyssey-bootstrap/raw/master/org.swift.libswift_5.0-electra2_iphoneos-arm.deb
mv org.swift.libswift_5.0-electra2_iphoneos-arm.deb libswift.deb
curl -sLO https://cdn.discordapp.com/attachments/688126487588634630/1026673680387936256/com.ex.substitute_2.3.1_iphoneos-arm.deb
mv com.ex.substitute_2.3.1_iphoneos-arm.deb substitute.deb
curl -sLO https://apt.bingner.com/debs/1443.00/com.saurik.substrate.safemode_0.9.6005_iphoneos-arm.deb
mv com.saurik.substrate.safemode_0.9.6005_iphoneos-arm.deb safemode.deb
curl -sLO http://apt.thebigboss.org/repofiles/cydia/debs2.0/preferenceloader_2.2.6.deb
mv preferenceloader_2.2.6.deb preferenceloader.deb
cd ../..