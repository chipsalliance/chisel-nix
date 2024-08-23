use num_bigint::{BigUint, RandBigInt};
use num_traits::Zero;
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
            test_num: 0,
            last_input_cycle: 0,
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

        fn biguint_to_vec(x: &BigUint) -> Vec<u8> {
            let mut x_bytes = x.to_bytes_le();
            x_bytes.resize(8, 0);
            x_bytes
        }

        let mut rng = rand::thread_rng();
        let x = rng.gen_biguint(self.data_width);
        let y = rng.gen_biguint(self.data_width);

        self.last_input_cycle = get_time();
        self.test_num += 1;
        TestPayload {
            valid: 1,
            bits: TestPayloadBits {
                x: biguint_to_vec(&x),
                y: biguint_to_vec(&y),
                result: biguint_to_vec(&gcd(x, y)),
            },
        }
    }

    pub(crate) fn watchdog(&mut self) -> u8 {
        const WATCHDOG_CONTINUE: u8 = 0;
        const WATCHDOG_TIMEOUT: u8 = 1;
        const WATCHDOG_FINISH: u8 = 2;

        let tick = get_time();
        if self.test_num >= self.test_size {
            info!("[{tick}] test finished, exiting");
            WATCHDOG_FINISH
        } else if tick - self.last_input_cycle > self.timeout {
            error!("[{tick}] watchdog timeout ");
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
            trace!("[{}] watchdog continue", tick);
            WATCHDOG_CONTINUE
        }
    }

    #[cfg(feature = "trace")]
    fn start_dump_wave(&mut self) {
        use crate::dpi::dump_wave;
        dump_wave(self.scope, &self.wave_path);
    }
}
