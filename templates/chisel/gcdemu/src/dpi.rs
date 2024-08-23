use std::ffi::{c_char, CString};
use std::sync::Mutex;

use crate::drive::Driver;
use svdpi::sys::dpi::{svBitVecVal, svLogic};
use svdpi::SvScope;
use crate::GcdArgs;
use clap::Parser;

pub type SvBitVecVal = u32;

// --------------------------
// preparing data structures
// --------------------------

static DPI_TARGET: Mutex<Option<Box<Driver>>> = Mutex::new(None);

#[repr(C)]
pub(crate) struct TestPayloadBits {
    pub(crate) x: Vec<u8>,
    pub(crate) y: Vec<u8>,
    pub(crate) result: Vec<u8>,
}
#[repr(C)]
pub(crate) struct TestPayload {
    pub(crate) valid: svLogic,
    pub(crate) bits: TestPayloadBits,
}

unsafe fn write_to_pointer(dst: *mut u8, data: &[u8]) {
    let dst = std::slice::from_raw_parts_mut(dst, data.len());
    dst.copy_from_slice(data);
}

unsafe fn fill_test_payload(dst: *mut SvBitVecVal, data_width: u64, payload: &TestPayload) {
    let data_len = (data_width / 8) as usize;
    assert!(
        payload.bits.x.len() == payload.bits.y.len()
            && payload.bits.y.len() == payload.bits.result.len()
    );
    assert!(payload.bits.result.len() <= data_len);
    let data = vec![payload.valid]
        .iter()
        .chain(payload.bits.x.iter())
        .chain(payload.bits.y.iter())
        .chain(payload.bits.result.iter())
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
}

#[no_mangle]
unsafe extern "C" fn gcd_watchdog(reason: *mut c_char) {
    let mut driver = DPI_TARGET.lock().unwrap();
    if let Some(driver) = driver.as_mut() {
        // FIXME
        // let code = driver.watchdog();
        // if code != 0 {
        //     exit(code as i32);
        // }
        *reason = driver.watchdog() as c_char
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
