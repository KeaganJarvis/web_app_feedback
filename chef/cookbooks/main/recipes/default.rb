package "git-core"
package "nginx"
# package "make"
# package "gcc"
# package "perl"
# package "cpanminus"
package "sqlite"
package "python3"
package "python3-pip"
package "python3-virtualenv"

git "/web_app_feedback/" do
    repository "https://github.com/KeaganJarvis/web_app_feedback.git"
    reference "main"
    action :sync
end

# TODO separate the next steps into a separate file/recipe

# get nginx setup correctly before doing certbot stuff so that it auto fixes /etc/nginx/sites-enabled/application

# certbot is recommended to use the snap install rather for 20.04
# attempts at using `snap_package` was giving errors TODO say this?
execute "Install certbot" do
    command "snap install certbot --classic"
end

# run this command to get https: certbot --nginx -d web-app-feedback.space -d www.web-app-feedback.space --non-interactive --agree-tos -m webmaster@example.com
# Note this command was interactive on first run through (added on --non-interactive --agree-tos -m webmaster@example.com).
# Second note this requires the @.web-app-feedback.space domain A record to point to the public IP of the instance

# create /etc/letsencrypt/renewal-hooks/post/ that restarts nginx

# note avoided using the Python cookbooks, like Poise-python because they seem unmaintained
execute "Create web_app_py_virtual_env" do
    command "virtualenv -p python3 /web_app_venv/"
end

execute "Install python libraries" do
    command "/web_app_venv/bin/pip install -r /web_app_feedback/web_app/requirements.txt"
end


# ensure to run ln -s /etc/nginx/sites-available/application /etc/nginx/sites-enabled when setting up nginx
# and systemctl restart nginx afterwards
# Should it use the nginx cookbook? If yes then use

# necessary for uwsgi logging:
directory '/var/log/uwsgi' do
    owner 'root'
    group 'root'
    mode '0755'
    action :create
end

# install the uswgi service files in systemd,
systemd_unit 'uwsgi-application.service' do
    content({ Unit: {
              Description: 'Feedback Web application UWSGI Workers',
              After: 'network.target nginx.service',
            },
            Service: {
              Type: 'notify',
              ExecStart: '/web_app_venv/bin/uwsgi --die-on-term --ini /web_app_feedback/web_app/uwsgi.ini',
              Restart: 'always',
              WorkingDirectory: '/web_app_feedback/web_app/'
            },
            Install: {
              WantedBy: 'multi-user.target',
            } })
    action [:create, :enable, :start] # TODO :start OR :restart ?
    # user ubunutu TODO get correct user
end









###########
#OLD:
# execute "Install perl web framework" do
#     command "cpanm Dancer2"
# end

# execute "Install perl ORM" do
#     command "cpanm Rose::DB::Object"
# end

# execute "Install ORLite" do # ORLIte won't install cause
#     command "cpanm ORLite"
# end
# knife supermarket install perl

# ensure `make` `gcc` and `cpanm` are installed,
# use `cpanm Dancer2`
# cpan_module 'App::Dancer2'