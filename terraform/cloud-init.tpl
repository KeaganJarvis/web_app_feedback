# The default is to install from packages.

# Key from https://packages.chef.io/chef.asc
# apt:
#   sources:
#     source1:
#       source: "deb http://packages.chef.io/repos/apt/stable $RELEASE main"
#       key: |
#         -----BEGIN PGP PUBLIC KEY BLOCK-----
#         Version: GnuPG v1.4.12 (Darwin)
#         Comment: GPGTools - http://gpgtools.org

#         mQGiBEppC7QRBADfsOkZU6KZK+YmKw4wev5mjKJEkVGlus+NxW8wItX5sGa6kdUu
#         twAyj7Yr92rF+ICFEP3gGU6+lGo0Nve7KxkN/1W7/m3G4zuk+ccIKmjp8KS3qn99
#         dxy64vcji9jIllVa+XXOGIp0G8GEaj7mbkixL/bMeGfdMlv8Gf2XPpp9vwCgn/GC
#         JKacfnw7MpLKUHOYSlb//JsEAJqao3ViNfav83jJKEkD8cf59Y8xKia5OpZqTK5W
#         ShVnNWS3U5IVQk10ZDH97Qn/YrK387H4CyhLE9mxPXs/ul18ioiaars/q2MEKU2I
#         XKfV21eMLO9LYd6Ny/Kqj8o5WQK2J6+NAhSwvthZcIEphcFignIuobP+B5wNFQpe
#         DbKfA/0WvN2OwFeWRcmmd3Hz7nHTpcnSF+4QX6yHRF/5BgxkG6IqBIACQbzPn6Hm
#         sMtm/SVf11izmDqSsQptCrOZILfLX/mE+YOl+CwWSHhl+YsFts1WOuh1EhQD26aO
#         Z84HuHV5HFRWjDLw9LriltBVQcXbpfSrRP5bdr7Wh8vhqJTPjrQnT3BzY29kZSBQ
#         YWNrYWdlcyA8cGFja2FnZXNAb3BzY29kZS5jb20+iGAEExECACAFAkppC7QCGwMG
#         CwkIBwMCBBUCCAMEFgIDAQIeAQIXgAAKCRApQKupg++Caj8sAKCOXmdG36gWji/K
#         +o+XtBfvdMnFYQCfTCEWxRy2BnzLoBBFCjDSK6sJqCu0IENIRUYgUGFja2FnZXMg
#         PHBhY2thZ2VzQGNoZWYuaW8+iGIEExECACIFAlQwYFECGwMGCwkIBwMCBhUIAgkK
#         CwQWAgMBAh4BAheAAAoJEClAq6mD74JqX94An26z99XOHWpLN8ahzm7cp13t4Xid
#         AJ9wVcgoUBzvgg91lKfv/34cmemZn7kCDQRKaQu0EAgAg7ZLCVGVTmLqBM6njZEd
#         Zbv+mZbvwLBSomdiqddE6u3eH0X3GuwaQfQWHUVG2yedyDMiG+EMtCdEeeRebTCz
#         SNXQ8Xvi22hRPoEsBSwWLZI8/XNg0n0f1+GEr+mOKO0BxDB2DG7DA0nnEISxwFkK
#         OFJFebR3fRsrWjj0KjDxkhse2ddU/jVz1BY7Nf8toZmwpBmdozETMOTx3LJy1HZ/
#         Te9FJXJMUaB2lRyluv15MVWCKQJro4MQG/7QGcIfrIZNfAGJ32DDSjV7/YO+IpRY
#         IL4CUBQ65suY4gYUG4jhRH6u7H1p99sdwsg5OIpBe/v2Vbc/tbwAB+eJJAp89Zeu
#         twADBQf/ZcGoPhTGFuzbkcNRSIz+boaeWPoSxK2DyfScyCAuG41CY9+g0HIw9Sq8
#         DuxQvJ+vrEJjNvNE3EAEdKl/zkXMZDb1EXjGwDi845TxEMhhD1dDw2qpHqnJ2mtE
#         WpZ7juGwA3sGhi6FapO04tIGacCfNNHmlRGipyq5ZiKIRq9mLEndlECr8cwaKgkS
#         0wWu+xmMZe7N5/t/TK19HXNh4tVacv0F3fYK54GUjt2FjCQV75USnmNY4KPTYLXA
#         dzC364hEMlXpN21siIFgB04w+TXn5UF3B4FfAy5hevvr4DtV4MvMiGLu0oWjpaLC
#         MpmrR3Ny2wkmO0h+vgri9uIP06ODWIhJBBgRAgAJBQJKaQu0AhsMAAoJEClAq6mD
#         74Jq4hIAoJ5KrYS8kCwj26SAGzglwggpvt3CAJ0bekyky56vNqoegB+y4PQVDv4K
#         zA==
#         =IxPr
#         -----END PGP PUBLIC KEY BLOCK-----

# chef:

#   # Valid values are 'accept' and 'accept-no-persist'
#   chef_license: "accept"

#   # Valid values are 'gems' and 'packages' and 'omnibus'
#   install_type: "packages"

#   # Boolean: run 'install_type' code even if chef-client
#   #          appears already installed.
#   force_install: true

runcmd: # janky way to install and call chef when `chef` stanza was failing above
- wget https://packages.chef.io/files/stable/chef-workstation/21.9.613/ubuntu/18.04/chef-workstation_21.9.613-1_amd64.deb
- dpkg -i chef-workstation_21.9.613-1_amd64.deb
- sudo chef-client --chef-license accept
- git clone https://github.com/KeaganJarvis/web_app_feedback.git /web_app_feedback
- cd /web_app_feedback/chef/cookbooks/
- sudo chef-client --local-mode --override-runlist main

output: {all: '| tee -a /var/log/cloud-init-output.log'}