import 'package:flutter/material.dart';

class ListSection extends StatelessWidget {
  static const defaultTitlePadding = EdgeInsets.only(
    top: 15.0,
    left: 15.0,
    right: 15.0,
    bottom: 8.0,
  );

  final String? title;
  final EdgeInsetsGeometry titlePadding;
  final List<Widget>? children;
  final TextStyle? titleTextStyle;
  final int? maxLines;
  final Widget? subtitle;
  final EdgeInsetsGeometry subtitlePadding;

  ListSection({
    Key? key,
    this.title,
    this.titlePadding = defaultTitlePadding,
    this.maxLines,
    this.subtitle,
    this.subtitlePadding = defaultTitlePadding,
    this.children,
    this.titleTextStyle,
  }) : assert(maxLines == null || maxLines > 0);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (title != null)
        Padding(
          padding: titlePadding,
          child: Text(
            title!,
            style: titleTextStyle ??
                TextStyle(
                  color: Theme.of(context).accentColor,
                  fontWeight: FontWeight.bold,
                ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      if (subtitle != null)
        Padding(
          padding: subtitlePadding,
          child: subtitle,
        ),
      ListView.separated(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: children!.length,
        separatorBuilder: (BuildContext context, int index) =>
            Divider(height: 1),
        itemBuilder: (BuildContext context, int index) {
          return children![index];
        },
      ),
    ]);
  }
}
