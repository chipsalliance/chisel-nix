use clap::Parser;
use tracing::Level;
use tracing_subscriber::{EnvFilter, FmtSubscriber};

pub mod dpi;
pub mod drive;

#[derive(Parser)]
pub(crate) struct GcdArgs {
    #[cfg(feature = "trace")]
    #[arg(long)]
    dump_start: u64,

    #[cfg(feature = "trace")]
    #[arg(long)]
    dump_end: u64,

    #[cfg(feature = "trace")]
    #[arg(long)]
    pub wave_path: String,

    #[arg(long, default_value = "info")]
    pub log_level: String,

    #[arg(long, hide = true,default_value = env!("DESIGN_DATA_WIDTH"))]
    data_width: u64,

    #[arg(long, hide = true,default_value = env!("DESIGN_TIMEOUT"))]
    timeout: u64,

    #[arg(long, hide = true,default_value = env!("DESIGN_TEST_SIZE"))]
    test_size: u64,

    #[arg(long, hide = true,default_value = env!("CLOCK_FLIP_TIME"))]
    clock_flip_time: u64,
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
}
