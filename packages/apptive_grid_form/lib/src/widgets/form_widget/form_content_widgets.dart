import 'package:apptive_grid_form/apptive_grid_form.dart';
import 'package:apptive_grid_form/src/translation/apptive_grid_localization.dart';
import 'package:apptive_grid_form/src/util/submit_progress.dart';
import 'package:apptive_grid_form/src/widgets/apptive_grid_form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

/// Shows a spinner while loading the form data
class LoadingFormWidget extends StatelessWidget {
  /// Creates a new loading widget
  const LoadingFormWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator.adaptive(),
    );
  }
}

/// Displays the current form data with all customizations
class FormDataWidget extends StatelessWidget {
  /// Creates a new form data widget
  const FormDataWidget({
    super.key,
    required this.data,
    required this.formKey,
    required this.isSubmitting,
    required this.padding,
    this.titlePadding,
    this.titleStyle,
    required this.hideTitle,
    this.descriptionPadding,
    this.descriptionStyle,
    required this.hideDescription,
    this.componentBuilder,
    required this.hideButton,
    required this.buttonAlignment,
    this.buttonLabel,
    required this.submitForm,
    this.progress,
    this.scrollController,
  });

  /// The current form data
  final FormData data;

  /// A key to access the state of the current form
  final GlobalKey<FormState> formKey;

  /// A flag to signal the the form is currently being submitted
  final bool isSubmitting;

  /// Padding of the Items in the Form. If no Padding is provided a EdgeInsets.all(8.0) will be used.
  final EdgeInsetsGeometry padding;

  /// Style for the Form Title. If no style is provided [headline5] of the [TextTheme] will be used
  final TextStyle? titleStyle;

  /// Padding for the title. If no Padding is provided the [padding] is used
  final EdgeInsetsGeometry? titlePadding;

  /// Flag to hide the form title, default is false
  final bool hideTitle;

  /// Style for the Form Description. If no style is provided [bodyText1] of the [TextTheme] will be used
  final TextStyle? descriptionStyle;

  /// Padding for the description. If no Padding is provided the [padding] is used
  final EdgeInsetsGeometry? descriptionPadding;

  /// Flag to hide the form description, default is false
  final bool hideDescription;

  /// A custom Builder for Building custom Widgets for FormComponents
  final Widget? Function(BuildContext, FormComponent)? componentBuilder;

  /// Alignment of the Send Button
  final Alignment buttonAlignment;

  /// Label of the Button to submit a form.
  /// Defaults to a localized version of `Send`
  final String? buttonLabel;

  /// Show or hide the submit button at the bottom of the form.
  final bool hideButton;

  /// Triggers when the send button it tapped
  final Function() submitForm;

  /// The current submission progress
  final SubmitProgress? progress;

  /// Optional ScrollController for the Form
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final localization = ApptiveGridLocalization.of(context)!;
    final submitLink = data.links[ApptiveLinkType.submit];
    // Offset for title and description
    const indexOffset = 2;
    return Form(
      key: formKey,
      child: ListView.builder(
        controller: scrollController,
        itemCount: indexOffset +
            (data.components?.length ?? 0) +
            (submitLink != null ? 1 : 0),
        itemBuilder: (context, index) {
          // Title
          if (index == 0) {
            if (hideTitle || data.title == null) {
              return const SizedBox();
            } else {
              return Padding(
                padding: titlePadding ?? padding,
                child: Text(
                  data.title!,
                  style:
                      titleStyle ?? Theme.of(context).textTheme.headlineSmall,
                ),
              );
            }
          } else if (index == 1) {
            if (hideDescription || data.description == null) {
              return const SizedBox();
            } else {
              return Padding(
                padding: descriptionPadding ?? padding,
                child: Text(
                  data.description!,
                  style:
                      descriptionStyle ?? Theme.of(context).textTheme.bodyLarge,
                ),
              );
            }
          } else if (index < (data.components?.length ?? 0) + indexOffset) {
            final componentIndex = index - indexOffset;
            final component = data.components![componentIndex];
            final componentWidget = fromModel(component);
            if (componentWidget is EmptyFormWidget) {
              // UserReference Widget should be invisible in the Form
              // So returning without any Padding
              return componentWidget;
            } else {
              return IgnorePointer(
                ignoring: isSubmitting,
                child: Padding(
                  padding: padding,
                  child: Builder(
                    builder: (context) {
                      final customBuilder =
                          componentBuilder?.call(context, component);
                      if (customBuilder != null) {
                        return customBuilder;
                      } else {
                        return componentWidget;
                      }
                    },
                  ),
                ),
              );
            }
          } else {
            return Padding(
              padding: padding,
              child: Align(
                alignment: buttonAlignment,
                child: Builder(
                  builder: (_) {
                    if (isSubmitting) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const TextButton(
                            onPressed: null,
                            child: Center(
                              child: CircularProgressIndicator.adaptive(),
                            ),
                          ),
                          if (progress != null)
                            Padding(
                              padding: padding,
                              child: SubmitProgressWidget(progress: progress!),
                            ),
                        ],
                      );
                    } else if (!hideButton) {
                      return ElevatedButton(
                        onPressed: submitForm,
                        child: Text(
                          buttonLabel ??
                              data.properties?.buttonTitle ??
                              localization.actionSend,
                        ),
                      );
                    } else {
                      return const SizedBox();
                    }
                  },
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

/// Displays an error the occured while submitting
class FormErrorWidget extends StatelessWidget {
  /// Creates a new error widget
  const FormErrorWidget({
    super.key,
    required this.error,
    required this.padding,
    required this.didTapBackButton,
    this.scrollController,
    this.formData,
  });

  /// The error being displayed
  final dynamic error;

  /// Padding of the Items in the Form. If no Padding is provided a EdgeInsets.all(8.0) will be used.
  final EdgeInsetsGeometry padding;

  /// Triggers when the user taps the back button
  final Function() didTapBackButton;

  /// Optional ScrollController for the Form
  final ScrollController? scrollController;

  /// The current form data
  final FormData? formData;

  @override
  Widget build(BuildContext context) {
    final localization = ApptiveGridLocalization.of(context)!;
    final theme = Theme.of(context);
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(32.0),
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Lottie.asset(
            'packages/apptive_grid_form/assets/error.json',
            repeat: false,
          ),
        ),
        Text(
          localization.errorTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium,
        ),
        Padding(
          padding: padding,
          child: Text(
            error is http.Response
                ? '${error.statusCode}: ${error.body}'
                : error.toString(),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.error),
          ),
        ),
        Center(
          child: TextButton(
            onPressed: didTapBackButton,
            child: Text(localization.backToForm),
          ),
        ),
      ],
    );
  }
}

/// Displays a success message after a succesful submission
class SuccessfulSubmitWidget extends StatelessWidget {
  /// Creates a new success widget
  const SuccessfulSubmitWidget({
    super.key,
    required this.didTapAdditionalAnswer,
    this.scrollController,
    this.formData,
  });

  /// Triggers when the user taps the button to submit an additional answer
  final Function() didTapAdditionalAnswer;

  /// Optional ScrollController for the Form
  final ScrollController? scrollController;

  /// The current form data
  final FormData? formData;

  @override
  Widget build(BuildContext context) {
    final localization = ApptiveGridLocalization.of(context)!;
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(32.0),
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Lottie.asset(
            'packages/apptive_grid_form/assets/success.json',
            repeat: false,
          ),
        ),
        Text(
          formData?.properties?.successTitle ?? localization.sendSuccess,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        if (formData?.properties?.successMessage != null) ...[
          const SizedBox(height: 4),
          Text(
            formData!.properties!.successMessage!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        Center(
          child: TextButton(
            onPressed: didTapAdditionalAnswer,
            child: Text(
              formData?.properties?.afterSubmitAction?.buttonTitle ??
                  localization.additionalAnswer,
            ),
          ),
        ),
      ],
    );
  }
}

/// Displays a message after a submission has been saved locally
class SavedSubmitWidget extends StatelessWidget {
  /// Creates a new saved submission widget
  const SavedSubmitWidget({
    super.key,
    required this.didTapAdditionalAnswer,
    this.scrollController,
    this.formData,
  });

  /// Triggers when the user taps the button to submit an additional answer
  final Function() didTapAdditionalAnswer;

  /// Optional ScrollController for the Form
  final ScrollController? scrollController;

  /// The current form data
  final FormData? formData;

  @override
  Widget build(BuildContext context) {
    final localization = ApptiveGridLocalization.of(context)!;
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(32.0),
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Lottie.asset(
            'packages/apptive_grid_form/assets/saved.json',
            repeat: false,
          ),
        ),
        Text(
          localization.savedForLater,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Center(
          child: TextButton(
            onPressed: didTapAdditionalAnswer,
            child: Text(
              formData?.properties?.afterSubmitAction?.buttonTitle ??
                  localization.additionalAnswer,
            ),
          ),
        ),
      ],
    );
  }
}