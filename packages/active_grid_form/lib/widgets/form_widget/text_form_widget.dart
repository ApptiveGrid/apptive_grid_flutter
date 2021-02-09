part of active_grid_form_widgets;

/// FormComponent Widget to display a [StringFormComponent]
class TextFormWidget extends StatefulWidget {
  /// Creates a [TextFormField] to show and edit Text contained in [component]
  const TextFormWidget({Key key, @required this.component}) : super(key: key);

  /// Component this Widget should reflect
  final StringFormComponent component;

  @override
  _TextFormWidgetState createState() => _TextFormWidgetState();
}

class _TextFormWidgetState extends State<TextFormWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.component.data.value;
    _controller.addListener(() {
      widget.component.data.value = _controller.text;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return TextFormField(
      controller: _controller,
      validator: (input) {
        if (widget.component.required && (input == null || input.isEmpty)) {
          // TODO: Make this Message configurable
          return '${widget.component.property} is required';
        } else {
          return null;
        }
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
      expands: widget.component.options.multi,
      decoration: InputDecoration(
        helperText: widget.component.options.description,
        labelText: widget.component.options.label ?? widget.component.property,
        hintText: widget.component.options.placeholder,
      ),
    );
  }
}
