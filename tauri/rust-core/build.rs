fn main() {
    uniffi::generate_scaffolding("src/todo_core.udl").expect("Failed to generate scaffolding");
}
