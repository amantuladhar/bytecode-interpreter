#[derive(Debug, Clone, Default)]
pub struct Scanner {}

impl Scanner {
    pub fn new() -> Self {
        Self {}
    }
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    pub fn test1() {
        let mut scanner = Scanner::new();
    }
}
