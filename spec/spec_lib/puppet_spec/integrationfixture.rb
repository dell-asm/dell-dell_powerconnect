module PuppetSpec
  FIXTURE_DIR = File.join(dir = File.expand_path(File.dirname(__FILE__)), "fixtures") unless defined?(FIXTURE_DIR)
end

module PuppetSpec::Integrationfixture
  def integrationYML(my_module, component_name, name)
    dir = File.expand_path(File.dirname(__FILE__))
    dirarray = dir.split(File::SEPARATOR)
    dirarray.shift

    dirsource = ''
    for sdir in dirarray
      if sdir == my_module then
      break
      end
      sdir = '/'+sdir
      dirsource = dirsource + sdir
    end
    my_fixture_dir = dirsource+'/'+my_module+'/spec/fixtures/integration/puppet/provider/'+component_name

    file = File.join(my_fixture_dir, name)
    unless File.readable? file then
      fail Puppet::DevError, "fixture '#{name}' for #{my_fixture_dir} is not readable"
    end
    return file
  end

end
