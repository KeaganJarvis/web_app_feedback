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

execute "Create web_app_py_virtual_env" do
    command "virtualenv -p python3 /web_app_venv/"
end

execute "Install python libraries" do
    command "/web_app_venv/bin/pip install -r /web_app_feedback/server/requirements.txt"
end
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