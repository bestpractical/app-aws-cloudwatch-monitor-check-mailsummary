use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'App::AWS::CloudWatch::Monitor::Check::MailSummary',
    AUTHOR => 'Best Practical Solutions, LLC <modules@bestpractical.com>',
    ABSTRACT_FROM => 'lib/App/AWS/CloudWatch/Monitor/Check/MailSummary.pm',
    VERSION_FROM => 'lib/App/AWS/CloudWatch/Monitor/Check/MailSummary.pm',
    LICENSE => 'apache_2_0',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'https://github.com/bestpractical/app-aws-cloudwatch-monitor-check-mailsummary.git',
                web => 'https://github.com/bestpractical/app-aws-cloudwatch-monitor-check-mailsummary',
            },
        },
    },

    MIN_PERL_VERSION => '5.10.1',
    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',  # for TEST_REQUIRES
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    TEST_REQUIRES => {
        'FindBin' => 0,
        'File::Find' => 0,
        'File::Spec' => 0,
        'Test::More' => '0.98',  # for subtest()
    },
    PREREQ_PM => {
        'Getopt::Long' => '2.45',  # 2.36 is required for options we need, but at least 2.45 for bugfixes
        'parent' => 0,
        'strict' => 0,
        'Time::Piece' => 0,
        'Time::Seconds' => 0,
        'warnings' => 0,
        'App::AWS::CloudWatch::Monitor' => 0,
    },

    test => {
        TESTS => 't/*.t',
    },
);
