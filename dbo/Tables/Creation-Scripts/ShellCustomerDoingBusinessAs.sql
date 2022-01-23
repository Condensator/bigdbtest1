SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ShellCustomerDoingBusinessAs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[DoingBusinessAsName] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[EffectiveDate] [date] NULL,
	[Comments] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ShellCustomerDetailId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ShellCustomerDoingBusinessAs]  WITH CHECK ADD  CONSTRAINT [EShellCustomerDetail_ShellCustomerDoingBusinessAs] FOREIGN KEY([ShellCustomerDetailId])
REFERENCES [dbo].[ShellCustomerDetails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ShellCustomerDoingBusinessAs] CHECK CONSTRAINT [EShellCustomerDetail_ShellCustomerDoingBusinessAs]
GO
