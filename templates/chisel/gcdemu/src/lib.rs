use plusarg::PlusArgMatcher;
use tracing::Level;
use tracing_subscriber::{EnvFilter, FmtSubscriber};

pub mod dpi;
pub mod drive;
pub mod plusarg;

pub(crate) struct GcdArgs {
    #[cfg(feature = "trace")]
    dump_start: u64,

    #[cfg(feature = "trace")]
    dump_end: u64,

    #[cfg(feature = "trace")]
    pub wave_path: String,

    pub log_level: String,
}

impl GcdArgs {
    pub fn setup_logger(&self) -> Result<(), Box<dyn std::error::Error>> {
        let log_level: Level = self.log_level.parse()?;
        let global_logger = FmtSubscriber::builder()
            .with_env_filter(EnvFilter::from_default_env())
            .with_max_level(log_level)
            .without_time()
            .with_target(false)
            .with_ansi(true)
            .compact()
            .finish();
        tracing::subscriber::set_global_default(global_logger)
            .expect("internal error: fail to setup log subscriber");
        Ok(())
    }

    pub fn from_plusargs(matcher: &PlusArgMatcher) -> Self {
        Self {
            #[cfg(feature = "trace")]
            dump_start: matcher.match_("dump-start").parse().unwrap(),
            #[cfg(feature = "trace")]
            dump_end: matcher.match_("dump-end").parse().unwrap(),
            #[cfg(feature = "trace")]
            wave_path: matcher.match_("wave-path").into(),
            log_level: matcher.try_match("log-level").unwrap_or("info").into(),
        }
    }
}
