use num_bigint::{BigUint, RandBigInt};
use num_traits::Zero;
use rand::Rng;
use tracing::{error, info, trace};

use crate::{
    dpi::{TestPayload, TestPayloadBits},
    GcdArgs,
};
use svdpi::{get_time, SvScope};

pub(crate) struct Driver {
    scope: SvScope,
    pub(crate) data_width: u64,
    pub(crate) timeout: u64,
    pub(crate) test_size: u64,
    pub(crate) clock_flip_time: u64,

    #[cfg(feature = "trace")]
    wave_path: String,
    #[cfg(feature = "trace")]
    dump_start: u64,
    #[cfg(feature = "trace")]
    dump_end: u64,
    #[cfg(feature = "trace")]
    dump_started: bool,

    test_num: u64,
    last_input_cycle: u64,
}

impl Driver {
    fn get_tick(&self) -> u64 {
        get_time() / self.clock_flip_time
    }

    pub(crate) fn new(scope: SvScope, args: &GcdArgs) -> Self {
        Self {
            scope,
            #[cfg(feature = "trace")]
            wave_path: args.wave_path.to_owned(),
            #[cfg(feature = "trace")]
            dump_start: args.dump_start,
            #[cfg(feature = "trace")]
            dump_end: args.dump_end,
            #[cfg(feature = "trace")]
            dump_started: false,
            data_width: args.data_width,
            timeout: args.timeout,
            test_size: args.test_size,
            clock_flip_time: args.clock_flip_time,
            test_num: 0,
            last_input_cycle: 0,
        }
    }

    pub(crate) fn init(&mut self) {
        #[cfg(feature = "trace")]
        if self.dump_start == 0 {
            self.start_dump_wave();
            self.dump_started = true;
        }
    }

    pub(crate) fn get_input(&mut self) -> TestPayload {
        fn gcd(x: BigUint, y: BigUint) -> BigUint {
            if y.is_zero() {
                x.clone()
            } else {
                gcd(y.clone(), x % y)
            }
        }

        let mut rng = rand::thread_rng();
        let x = rng.gen_biguint(self.data_width);
        let y = rng.gen_biguint(self.data_width);
        let result = gcd(x.clone(), y.clone());

        self.last_input_cycle = self.get_tick();
        self.test_num += 1;
        trace!(
            "[{}] the {}th input is x={} y={} result={}",
            self.get_tick(),
            self.test_num,
            &x,
            &y,
            &result
        );
        TestPayload {
            valid: if rand::thread_rng().gen::<f64>() < 0.95 {
                1
            } else {
                0
            },
            bits: TestPayloadBits { x, y, result },
        }
    }

    pub(crate) fn watchdog(&mut self) -> u8 {
        const WATCHDOG_CONTINUE: u8 = 0;
        const WATCHDOG_TIMEOUT: u8 = 1;
        const WATCHDOG_FINISH: u8 = 2;

        let tick = self.get_tick();
        if self.test_num >= self.test_size {
            info!("[{tick}] test finished, exiting");
            WATCHDOG_FINISH
        } else if tick - self.last_input_cycle > self.timeout {
            error!(
                "[{}] watchdog timeout, last input tick = {}",
                tick, self.last_input_cycle
            );
            WATCHDOG_TIMEOUT
        } else {
            #[cfg(feature = "trace")]
            if self.dump_end != 0 && tick > self.dump_end {
                info!("[{tick}] run to dump end, exiting");
                return WATCHDOG_FINISH;
            }

            #[cfg(feature = "trace")]
            if !self.dump_started && tick >= self.dump_start {
                self.start_dump_wave();
                self.dump_started = true;
            }
            trace!("[{tick}] watchdog continue");
            WATCHDOG_CONTINUE
        }
    }

    #[cfg(feature = "trace")]
    fn start_dump_wave(&mut self) {
        use crate::dpi::dump_wave;
        dump_wave(self.scope, &self.wave_path);
    }
}
