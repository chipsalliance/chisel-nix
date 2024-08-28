use std::cmp::max;
use std::ffi::{c_char, CString};
use std::sync::Mutex;

use crate::drive::Driver;
use crate::GcdArgs;
use clap::Parser;
use num_bigint::BigUint;
use svdpi::sys::dpi::{svBitVecVal, svLogic};
use svdpi::SvScope;

pub type SvBitVecVal = u32;

// --------------------------
// preparing data structures
// --------------------------

static DPI_TARGET: Mutex<Option<Box<Driver>>> = Mutex::new(None);

#[derive(Debug)]
pub(crate) struct TestPayloadBits {
    pub(crate) x: BigUint,
    pub(crate) y: BigUint,
    pub(crate) result: BigUint,
}
#[derive(Debug)]
pub(crate) struct TestPayload {
    pub(crate) valid: svLogic,
    pub(crate) bits: TestPayloadBits,
}

unsafe fn write_to_pointer(dst: *mut u8, data: &[u8]) {
    let dst = std::slice::from_raw_parts_mut(dst, data.len());
    dst.copy_from_slice(data);
}

unsafe fn fill_test_payload(dst: *mut SvBitVecVal, data_width: u64, payload: &TestPayload) {
    let biguint_to_vec = |x: &BigUint| -> Vec<u8> {
        let mut x_bytes = x.to_bytes_le();
        x_bytes.resize((data_width as f64 / 8f64).ceil() as usize, 0);
        x_bytes
    };

    assert!(
        max(
            max(payload.bits.x.bits(), payload.bits.y.bits()),
            payload.bits.result.bits()
        ) <= data_width
    );

    // The field in the struct is the most significant first
    let data = (biguint_to_vec(&payload.bits.result).iter())
        .chain(biguint_to_vec(&payload.bits.y).iter())
        .chain(biguint_to_vec(&payload.bits.x).iter())
        .chain(vec![payload.valid].iter())
        .cloned()
        .collect::<Vec<u8>>();
    write_to_pointer(dst as *mut u8, &data);
}

//----------------------
// dpi functions
//----------------------

#[no_mangle]
unsafe extern "C" fn gcd_init() {
    let args = GcdArgs::parse();
    args.setup_logger().unwrap();
    let scope = SvScope::get_current().expect("failed to get scope in gcd_init");
    let driver = Box::new(Driver::new(scope, &args));

    let mut dpi_target = DPI_TARGET.lock().unwrap();
    assert!(dpi_target.is_none(), "gcd_init should be called only once");
    *dpi_target = Some(driver);

    if let Some(driver) = dpi_target.as_mut() {
        driver.init();
    }
}

#[no_mangle]
unsafe extern "C" fn gcd_watchdog(reason: *mut c_char) {
    let mut driver = DPI_TARGET.lock().unwrap();
    if let Some(driver) = driver.as_mut() {
        *reason = driver.watchdog() as c_char;
    }
}

#[no_mangle]
unsafe extern "C" fn gcd_input(payload: *mut svBitVecVal) {
    let mut driver = DPI_TARGET.lock().unwrap();
    if let Some(driver) = driver.as_mut() {
        fill_test_payload(payload, driver.data_width, &driver.get_input());
    }
}

//--------------------------------
// import functions and wrappers
//--------------------------------

mod dpi_export {
    use std::ffi::c_char;
    extern "C" {
        #[cfg(feature = "trace")]
        /// `export "DPI-C" function dump_wave(input string file)`
        pub fn dump_wave(path: *const c_char);
    }
}

#[cfg(feature = "trace")]
pub(crate) fn dump_wave(scope: SvScope, path: &str) {
    use svdpi::set_scope;

    let path_cstring = CString::new(path).unwrap();

    set_scope(scope);
    unsafe {
        dpi_export::dump_wave(path_cstring.as_ptr());
    }
}
