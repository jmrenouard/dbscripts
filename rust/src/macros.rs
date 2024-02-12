pub mod macros {
    #[macro_export]
    macro_rules! f {
		($($arg:tt)*) => {
				format!($($arg)*)
		};
	}
}
